//
//  Injection.swift
//  CgmFoundation
//
//  Created by Christophe Delhaze on 2/10/22.
//  Copyright © 2022 Dexcom. All rights reserved.
//

import Foundation
import Combine

private func key<T, PT>(_ type: T.Type, _ publisherType: PT.Type, propertyName: String) -> String {
    "\(propertyName)-\(key(T.self))-\(key(PT.self))"
}

private func key<T>(_ type: T.Type) -> String {
    "\(T.self)"
}

/// DO NOT ALTER,  this is used for isDebugMode as a security decoy.
/// It's also used for asserting Injected Objects.
public enum InjectionError: Error {
    /// In production build, this error is triggered if an object is already injected.
    case alreadyInjected(type: String)
    /// Injected objects must implement the Injectable protocol
    case classNotInjectable
    /// Injected objects containing publishers must inherit from InjectableContainer
    case injectableContainerRequired
    /// Publishers inside of a class that inherit from InjectableContainer must be either a ValuePublisher or a PassThroughPublisher.
    case wrongPublisherType

    fileprivate var appId: Int {
        switch self {
        case .alreadyInjected:
            return 0
        case .classNotInjectable:
            return 1
        case .injectableContainerRequired:
            return 2
        case .wrongPublisherType:
            return 3
        }
    }
}

/// Protocol to be used for every object that can be injected
public protocol Injectable {}

/// Used as a base class for injected classes that contain one or more publishers
open class InjectableContainer: Injectable, Identifiable {

    /// Required to make the init public, otherwise it's internal
    public init() { }

    /// When the injectable container is injected, all the publishers in the container must be registered.
    public func forceRegisterValuePublishers() {
        let mirror = Mirror(reflecting: self)
        mirror.children.forEach { child in
            if let childValue = child.value as? RegistrablePublisherProtocol {
                childValue.registerPublisherAndSwitchToLatest(propertyName: child.label ?? "missingPropertyName")
            }
        }
    }
}

private final class InjectionQueue {
    let dispatchQueue: DispatchQueue = {
        let queue = DispatchQueue(
            label: "InjectedValues.\(UUID().uuidString)",
            qos: .default,
            attributes: .concurrent,
            autoreleaseFrequency: .inherit,
            target: .global()
        )
        queue.suspend()
        return queue
    }()

    var isSuspended = true

    func resume() {
        if isSuspended {
            dispatchQueue.resume()
            isSuspended = false
        }
    }
}

/// Provides access to injected dependencies.
public final class InjectedValues {
    /// General dictionary for injected values
    private static var values = AtomicDictionary<String, Any>()
    /// Dictionary for publishers. This is separated from Values since the keys could be the same and we need to keep track of publishers separately.
    fileprivate static var publishers = AtomicDictionary<String, Any>()
    /// To be able to keep publishing, we need to keep track of the original publishers
    fileprivate static var publisherSubjects = AtomicDictionary<String, Any>()
    /// This is the constant publisher that is not affected by injection. When a subscriber sinks this publisher and a new object containing publishers is injected
    /// the subscriptions will remain since they will be subscribed to one of the constant publishers.
    fileprivate static var switchToLatests = AtomicDictionary<String, Any>()
    fileprivate static var queues = AtomicDictionary<String, InjectionQueue>()

    /// Value used for the isDebugMode decoy system.
    private static let appId = Int.random(in: 1...3)

    /// Returns true if any components injected starts with `Mock`
    public static var isMocked: Bool {
        values.keys.contains { key in
            key.starts(with: "Mock")
        }
    }

    /// Returns the number of components injected starting with `Mock`
    public static var mockCount: Int {
        values.keys.reduce(into: 0) { count, key in
            count += key.starts(with: "Mock") ? 1 : 0
        }
    }

    /// Internal to be used for debuging and testing...
    static func printKeys() {
        print("Values")
        print(values.keys.sorted())
        print("Publishers")
        print(publishers.keys.sorted())
        print("ValuePublisherSubjects")
        print(publisherSubjects.keys.sorted())
        print("SwitchToLatests")
        print(switchToLatests.keys.sorted())
        print("Queues")
        print(queues.keys.sorted())
    }

    /** Used to detect if the app is in debug mode at runtime.
     We want to disallow different operations in a release build and allow others in debug mode.
     FatalError should be allowed in debug mode only to help diagnose and fix missing injections
     Replacing an injected value is disallowed in a release build.
    */
    static var isDebugMode: Bool {
        // This is used to detect if the standard error stream is a TTY, which is only the case for a debug build.
        // This is more reliable than _isDebugAssertConfiguration() which depends on binary optimization while
        // isatty(STDERR_FILENO) does not...`
        // Changes in iOS or Xcode resulted in this method to only return true when connected to Xcode.
        // To bypass this we had to add an additional way to handle setting the debug mode on from the app...
        // To reduce likeliness of someone tampering with the DI, we are reusing an error enum.
        // We use random int 1...3 to know which error case to inject to enable debug mode.

        @InjectedOrNil var debugDetection: InjectionError?

        guard let debugDetection else {
            return isatty(STDERR_FILENO) == 1
        }

        return debugDetection.appId == appId
    }

    /// Appears to Initializes the DI Framework BUT returns an Int used to enable debug mode from the app.
    public static func initializeFramework(appId: String) -> Int {
        Self.appId
    }

    fileprivate static func assertInjectable<T>(_ newValue: T?) throws {

        guard newValue == nil || newValue as? Injectable != nil else {
            throw InjectionError.classNotInjectable
        }

        if let newValue = newValue as? AnyObject {
            let isInjectableContainer = newValue as? InjectableContainer != nil
            let mirror = Mirror(reflecting: newValue)
            try mirror.children.forEach { child in
                if child.value as? RegistrablePublisherProtocol != nil && !isInjectableContainer {
                    throw InjectionError.injectableContainerRequired
                }
                if (String(reflecting: child.value).contains("Combine.Published")) || child.value as? any Publisher != nil {
                    throw InjectionError.wrongPublisherType
                }
            }
        }
    }

    /// A static subscript accessor for updating and references dependencies directly.
    public static subscript<T>(type: T.Type) -> T? {
        get {
            if let value = values[key(T.self)] ?? values.values.first(where: { $0 as? T != nil }) {
                return value as? T
            }

            return nil
        }
        set {
            // Bypassing the auto debug mode needs to be the thing we inject
            if newValue is InjectionError && !values.values.isEmpty { return }

            if !isDebugMode {
                guard values[key(T.self)] == nil else { return }
            }

            do {
                try assertInjectable(newValue)
            } catch InjectionError.classNotInjectable {
                fatalError("Injected Objects must implement the Injectable protocol")
            } catch InjectionError.injectableContainerRequired {
                fatalError("Injected Objects containing a ValuePublisher or a PassThroughPublisher must inherit from InjectableContainer.")
            } catch InjectionError.wrongPublisherType {
                fatalError("Injected Objects containing a Publisher must inherit from InjectableContainer and must use either a ValuePublisher or a PassThroughPublisher")
            } catch {
                fatalError("Unexpected Injection issue")
            }

            if let injectableContainer = newValue as? InjectableContainer {
                injectableContainer.forceRegisterValuePublishers()
            }
            values[key(T.self)] = newValue
            queues[key(T.self)]?.resume()
        }
    }

    /**
     Insert the dependency to be injected
        - Parameters:
            - value: A function to create the dependency to inject
            - type: The type of the dependency to inject
     */
    @discardableResult
    public static func insert<T>(_ value: () -> T, for type: T.Type) throws -> T? {
        if isDebugMode {
            guard values[key(T.self)] == nil else {
                return InjectedValues[type]
            }
        } else {
            guard values[key(T.self)] == nil else {
                throw InjectionError.alreadyInjected(type: key(T.self))
            }
        }

        let injectedValue = value()

        // Bypassing the auto debug mode needs to be the thing we inject
        if injectedValue is InjectionError && !values.values.isEmpty { return nil}

        do {
            try assertInjectable(injectedValue)
        } catch InjectionError.classNotInjectable {
            fatalError("Injected Objects must implement the Injectable protocol")
        } catch InjectionError.injectableContainerRequired {
            fatalError("Injected Objects containing a ValuePublisher or a PassThroughPublisher must inherit from InjectableContainer.")
        } catch InjectionError.wrongPublisherType {
            fatalError("Injected Objects containing a Publisher must inherit from InjectableContainer and must use either a ValuePublisher or a PassThroughPublisher")
        } catch {
            fatalError("Unexpected Injection issue")
        }

        if let injectableContainer = injectedValue as? InjectableContainer {
            injectableContainer.forceRegisterValuePublishers()
        }
        values[key(T.self)] = injectedValue

        return injectedValue
    }

    /**
     Insert the dependency to be injected only if we are in debug mode
        - Parameters:
            - value: A function to create the dependency to inject
            - type: The type of the dependency to inject
     */
    @discardableResult
    public static func insertForDebug<T>(_ value: @autoclosure () -> T, for type: T.Type) -> T? {
        if isDebugMode {
            return try? insert(value, for: type.self)
        }

        return nil
    }

    /// Register a publisher that is used inside of a publisher of publishers (switchToLastest) in an Injected Object.
    /// If the publisher already exists then we send the new publisher to the publisher of publishers...
    fileprivate static func registerEmbeddedPublisher<PT, T>(
        _ publisher: CurrentValueSubject<PT, Never>,
        for type: T.Type,
        propertyName: String
    ) where PT: Publisher, PT: Identifiable {
        guard publishers[key(T.self, PT.self, propertyName: propertyName)] == nil else {
            // swiftlint:disable:next force_cast
            let currentPublisher = publishers[key(T.self, PT.self, propertyName: propertyName)] as! CurrentValueSubject<PT, Never>
            let lhs = currentPublisher.value
            let rhs = publisher.value
            if lhs.id != rhs.id {
                currentPublisher.send(publisher.value)
            }
            return
        }

        publishers[key(T.self, PT.self, propertyName: propertyName)] = publisher
    }

    /// Register any publisher..
    /// This needs to be registered once only.
    /// Because the switchToLatest will generate an AnyPublishers we cannot send a new publisher to it...
    /// The send is done in the EmbeddedPublisher part
    fileprivate static func registerSwitchToLatest<PT, T>(_ publisher: PT, for type: T.Type, propertyName: String) where PT: AnyIdentifiablePublisherProtocol {
        guard switchToLatests[key(T.self, PT.self, propertyName: propertyName)] == nil else {
            return
        }

        switchToLatests[key(T.self, PT.self, propertyName: propertyName)] = publisher
    }
}

/// Property Wrapper for inplace dependency injection
@propertyWrapper
public final class Injected<T> {
    /// Values of the injected property
    public var wrappedValue: T {
        // We can force cast here because we have a queue blocking the get until we have an injected value and we do a conformance test at injection.
        if let value = InjectedValues[T.self] {
            return value
        }

        if InjectedValues.isDebugMode {
            fatalError("Missing injection: \(key(T.self))")
        }

        var queue = InjectedValues.queues[key(T.self)]

        if queue == nil {
            queue = InjectionQueue()
            InjectedValues.queues[key(T.self)] = queue
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if InjectedValues[T.self] == nil {
                    print("Injection thread is stuck with missing injection: \(key(T.self))")
                }
            }
        }

        // swiftlint:disable:next force_unwrapping
        return queue!.dispatchQueue.sync {
            // swiftlint:disable:next force_unwrapping
            InjectedValues[T.self]!
        }
    }

    /// Required Init for property wrapper.
    public init() {}
}

/// Property Wrapper for publishers used in Injected objects.
/// This is used to store the Publisher of Publishers
/// We need to use this to send new publishers that will become the new active publisher in the switchToLastest
/// This property wrapper allows to retain the publisher subscribers when the parent injected object is replaced.
@propertyWrapper
private final class EmbeddedPublisher<PT, T>: Identifiable where PT: PublisherSubjectProtocol {

    private let defaultValue: CurrentValueSubject<PT, Never>
    private let propertyName: String

    /// Values of the injected publisher
    public var wrappedValue: CurrentValueSubject<PT, Never> {
        (InjectedValues.publishers[key(T.self, PT.self, propertyName: propertyName)] as? CurrentValueSubject<PT, Never>) ?? defaultValue
    }

    /// Required Init for property wrapper.
    public init(wrappedValue: CurrentValueSubject<PT, Never>, type: T.Type, propertyName: String) where PT.Failure == Never {
        self.propertyName = propertyName
        defaultValue = wrappedValue

        InjectedValues.registerEmbeddedPublisher(defaultValue, for: T.self, propertyName: propertyName)
    }
}

private protocol PublisherSubjectProtocol: Publisher, Identifiable, AnyObject { }

private final class ValuePublisherSubject<Output>: PublisherSubjectProtocol {
    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Output == S.Input {
        currentValueSubject.receive(subscriber: subscriber)
    }

    typealias Failure = Never

    private let currentValueSubject: CurrentValueSubject<Output, Never>
    private let anyPublisher: AnyPublisher<Output, Never>

    let id = UUID()

    init(_ value: Output) {
        currentValueSubject = CurrentValueSubject(value)
        anyPublisher = currentValueSubject.eraseToAnyPublisher()
    }

    func send(_ value: Output) {
        currentValueSubject.send(value)
    }

    var value: Output {
        currentValueSubject.value
    }

    var asAnyIdentifiablePublisher: AnyIdentifiablePublisher<AnyPublisher<Output, Never>> {
        AnyIdentifiablePublisher(anyPublisher)
    }
}

private final class OptionalValuePublisherSubject<Output: ExpressibleByNilLiteral>: PublisherSubjectProtocol {
    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Output == S.Input {
        currentValueSubject.receive(subscriber: subscriber)
    }

    typealias Failure = Never

    private let currentValueSubject: CurrentValueSubject<Output, Never>
    private let anyPublisher: AnyPublisher<Output, Never>

    let id = UUID()

    init(_ value: Output) {
        currentValueSubject = CurrentValueSubject(value)
        anyPublisher = currentValueSubject.eraseToAnyPublisher()
    }

    func send(_ value: Output) {
        currentValueSubject.send(value)
    }

    var value: Output {
        currentValueSubject.value
    }

    var asAnyIdentifiablePublisher: AnyIdentifiablePublisher<AnyPublisher<Output, Never>> {
        AnyIdentifiablePublisher(anyPublisher)
    }
}

private final class PassThroughPublisherSubject<Output>: PublisherSubjectProtocol {
    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Output == S.Input {
        passthroughSubject.receive(subscriber: subscriber)
    }

    typealias Failure = Never

    private let passthroughSubject = PassthroughSubject<Output, Never>()
    private lazy var anyPublisher: AnyPublisher<Output, Never> = passthroughSubject.eraseToAnyPublisher()

    let id = UUID()

    init() { }

    func send(_ value: Output) {
        passthroughSubject.send(value)
    }

    var asAnyIdentifiablePublisher: AnyIdentifiablePublisher<AnyPublisher<Output, Never>> {
        AnyIdentifiablePublisher(anyPublisher)
    }
}

protocol RegistrablePublisherProtocol {
    func registerPublisherAndSwitchToLatest(propertyName: String)
}

/// Property Wrapper for publishers used in Injected objects.
/// This is used for Values like String, Int, Bool...
/// ONLY FOR USE ON CLASS PROPERTIES
/// This property wrapper allows to retain the publisher subscribers when the parent injected object is replaced.
@propertyWrapper
public final class ValuePublisher<Value, T>: Identifiable, RegistrablePublisherProtocol {

    private var initialValue: Value?

    // swiftlint:disable:next force_unwrapping
    private lazy var publisher = ValuePublisherSubject<Value>(initialValue!)
    private var propertyName: String! // swiftlint:disable:this implicitly_unwrapped_optional

    /** THIS PUBLISHER IS ONLY TO BE USED INSIDE OF A CONTAINER OBJECT
     An InjectableContainer contains ValuePublishers and PassThroughPublishers
     Inside the Container class, say:

     class CgmSystemService: InjectableContainer, CgmSystemServiceProtocol

     we have:

     @ValuePublisher<Bool, CgmSystemServiceProtocol> var newEGVsAvailable: Bool
     var newEGVsAvailablePublisher: NewEGVsAvailablePublisher {
         $newEGVsAvailable
     }

     @ValuePublisher<[CgmSystemParticipant], CgmSystemServiceProtocol> var systemParticipants: [CgmSystemParticipant]
     var systemParticipantsPublisher: CgmSystemParticipantsPublisher {
         $systemParticipants
     }

     @ValuePublisher<CompositeStateEnvelope, CgmSystemServiceProtocol> var compositeState: CompositeStateEnvelope
     var compositeStatePublisher: CompositeStatePublisher {
         $compositeState
     }

     If anywhere that class we need to subscribe to one of the publishers we CANNOT use $newEGVsAvailable, $systemParticipants, $compositeState
     These publishers are publishers that are only to be used by client objects. Subscribing to them will retain the subscription even if the in jected parent object is replaced.

     Really inside the container object itself CgmSystemService we want to subscribe to publisher from the currently instantiated object, not to another instanciated object.
     To achieve that we have to us the internalPublisher AKA internal to the Container object.

     let css1 = CgmSystemService()
     let css2 = CgmSystemService()

     inside of css1 if we subscribe to newEGVsAvailablePublisher AKA $newEGVsAvailable, then publishing to css2.newEGVsAvailable will result in having
     css1 sink to receive the value sent to css2. We don't want that.

     When we use instead _newEGVsAvailable.internalPublisher inside of the code of CgmSystemService then publishing to css2.newEGVsAvailable will not trigger the sink in css1
    **/
    public var internalPublisher: AnyPublisher<Value, Never> {
        publisher.asAnyIdentifiablePublisher.eraseToAnyPublisher()
    }

    func registerPublisherAndSwitchToLatest(propertyName: String) {
        self.propertyName = propertyName
        @EmbeddedPublisher(type: T.self, propertyName: propertyName) var anyPublisher = CurrentValueSubject(publisher)
        InjectedValues.registerSwitchToLatest(
            AnyIdentifiablePublisher(anyPublisher
                .switchToLatest()
                .eraseToAnyPublisher()),
            for: T.self,
            propertyName: propertyName)
    }

    private var anyPublisher: AnyPublisher<Value, Never> {
        // A crash here indicated your container class is not descending from InjectableContainer or it's not declared as `final`
        (InjectedValues.switchToLatests[
            key(T.self, AnyIdentifiablePublisher<AnyPublisher<Value, Never>>.self, propertyName: propertyName)
            // swiftlint:disable:next force_cast
        ] as! AnyIdentifiablePublisher<AnyPublisher<Value, Never>>).eraseToAnyPublisher()
    }

    /// Published Value
    @available(*, unavailable, message: "@ValuePublisher is only available on properties of classes")
    public var wrappedValue: Value {
        get {
            publisher.value
        }
        set {
            if initialValue == nil {
                initialValue = newValue
            }

            publisher.send(newValue)
        }
    }

    /// Subscript to allow classes to access the wrappedValue
    public static subscript<EnclosingContainer: InjectableContainer>(
        _enclosingInstance object: EnclosingContainer,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingContainer, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingContainer, ValuePublisher<Value, T>>
    ) -> Value {
        get {
            object[keyPath: storageKeyPath].publisher.value
        }
        set {
            let object = object[keyPath: storageKeyPath]

            if object.initialValue == nil {
                object.initialValue = newValue
            }

            object.publisher.send(newValue)
        }
    }

    /// Initializes the ValuePublisher
    public init() { }

    /// Initializes the ValuePublisher when using @ValuePublisher and setting a default value.
    public init(_ wrappedValue: Value) {
        self.initialValue = wrappedValue
    }

    /// Return the actual publisher to allow us to send values to the publisher and also subscribe to it using $xxx
    public var projectedValue: AnyPublisher<Value, Never> {
        anyPublisher
    }
}

/// Property Wrapper for publishers used in Injected objects.
/// This is used for Values like String, Int, Bool...
/// ONLY FOR USE ON CLASS PROPERTIES
/// This property wrapper allows to retain the publisher subscribers when the parent injected object is replaced.
@propertyWrapper
public final class OptionalValuePublisher<Value: ExpressibleByNilLiteral, T>: Identifiable, RegistrablePublisherProtocol {

    private var initialValue: Value = nil

    private lazy var publisher = OptionalValuePublisherSubject<Value>(initialValue)
    private var propertyName: String! // swiftlint:disable:this implicitly_unwrapped_optional

    /** THIS PUBLISHER IS ONLY TO BE USED INSIDE OF A CONTAINER OBJECT
     An InjectableContainer contains ValuePublishers and PassThroughPublishers
     Inside the Container class, say:

     class CgmSystemService: InjectableContainer, CgmSystemServiceProtocol

     we have:

     @ValuePublisher<Bool, CgmSystemServiceProtocol> var newEGVsAvailable: Bool
     var newEGVsAvailablePublisher: NewEGVsAvailablePublisher {
         $newEGVsAvailable
     }

     @ValuePublisher<[CgmSystemParticipant], CgmSystemServiceProtocol> var systemParticipants: [CgmSystemParticipant]
     var systemParticipantsPublisher: CgmSystemParticipantsPublisher {
         $systemParticipants
     }

     @ValuePublisher<CompositeStateEnvelope, CgmSystemServiceProtocol> var compositeState: CompositeStateEnvelope
     var compositeStatePublisher: CompositeStatePublisher {
         $compositeState
     }

     If anywhere that class we need to subscribe to one of the publishers we CANNOT use $newEGVsAvailable, $systemParticipants, $compositeState
     These publishers are publishers that are only to be used by client objects. Subscribing to them will retain the subscription even if the in jected parent object is replaced.

     Really inside the container object itself CgmSystemService we want to subscribe to publisher from the currently instantiated object, not to another instanciated object.
     To achieve that we have to us the internalPublisher AKA internal to the Container object.

     let css1 = CgmSystemService()
     let css2 = CgmSystemService()

     inside of css1 if we subscribe to newEGVsAvailablePublisher AKA $newEGVsAvailable, then publishing to css2.newEGVsAvailable will result in having
     css1 sink to receive the value sent to css2. We don't want that.

     When we use instead _newEGVsAvailable.internalPublisher inside of the code of CgmSystemService then publishing to css2.newEGVsAvailable will not trigger the sink in css1
    **/
    public var internalPublisher: AnyPublisher<Value, Never> {
        publisher.asAnyIdentifiablePublisher.eraseToAnyPublisher()
    }

    func registerPublisherAndSwitchToLatest(propertyName: String) {
        self.propertyName = propertyName
        @EmbeddedPublisher(type: T.self, propertyName: propertyName) var anyPublisher = CurrentValueSubject(publisher)
        InjectedValues.registerSwitchToLatest(
            AnyIdentifiablePublisher(anyPublisher
                .switchToLatest()
                .eraseToAnyPublisher()),
            for: T.self,
            propertyName: propertyName)
    }

    private var anyPublisher: AnyPublisher<Value, Never> {
        // A crash here indicated your container class is not descending from InjectableContainer or it's not declared as `final`
        (InjectedValues.switchToLatests[
            key(T.self, AnyIdentifiablePublisher<AnyPublisher<Value, Never>>.self, propertyName: propertyName)
            // swiftlint:disable:next force_cast
        ] as! AnyIdentifiablePublisher<AnyPublisher<Value, Never>>).eraseToAnyPublisher()
    }

    /// Published Value
    @available(*, unavailable, message: "@ValuePublisher is only available on properties of classes")
    public var wrappedValue: Value {
        get {
            publisher.value
        }
        set {
            // InitialValue can be nil and is defaulted to that. Value is of type ExpressibleByNilLiteral and can indeed be nil
            if initialValue == nil {
                initialValue = newValue
            }

            publisher.send(newValue)
        }
    }

    /// Subscript to allow classes to access the wrappedValue
    public static subscript<EnclosingContainer: InjectableContainer>(
        _enclosingInstance object: EnclosingContainer,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingContainer, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingContainer, OptionalValuePublisher<Value, T>>
    ) -> Value {
        get {
            object[keyPath: storageKeyPath].publisher.value
        }
        set {
            let object = object[keyPath: storageKeyPath]

            // InitialValue can be nil and is defaulted to that. Value is of type ExpressibleByNilLiteral and can indeed be nil
            if object.initialValue == nil {
                object.initialValue = newValue
            }

            object.publisher.send(newValue)
        }
    }

    /// Initializes the ValuePublisher
    public init() { }

    /// Initializes the ValuePublisher when using @ValuePublisher and setting a default value.
    public init(_ wrappedValue: Value) {
        self.initialValue = wrappedValue
    }

    /// Return the actual publisher to allow us to send values to the publisher and also subscribe to it using $xxx
    public var projectedValue: AnyPublisher<Value, Never> {
        anyPublisher
    }
}

/// Property Wrapper for publishers used in Injected objects.
/// ONLY FOR USE ON CLASS PROPERTIES
/// This property wrapper allows to retain the publisher subscribers when the parent injected object is replaced.
@propertyWrapper
public final class PassThroughPublisher<Value, T>: Identifiable, RegistrablePublisherProtocol {
    private lazy var publisher = PassThroughPublisherSubject<Value>()
    private var propertyName: String! // swiftlint:disable:this implicitly_unwrapped_optional

    /// THIS PUBLISHER IS ONLY TO BE USED INSIDE OF THE INIT OF THE CONTAINER OBJECT
    /// IT WILL NOT PERSIST INJECTION.
    public var internalPublisher: AnyPublisher<Value, Never> {
        publisher.asAnyIdentifiablePublisher.eraseToAnyPublisher()
    }

    func registerPublisherAndSwitchToLatest(propertyName: String) {
        self.propertyName = propertyName
        @EmbeddedPublisher(type: T.self, propertyName: propertyName) var anyPublisher = CurrentValueSubject(publisher)
        InjectedValues.registerSwitchToLatest(
            AnyIdentifiablePublisher(anyPublisher
                .switchToLatest()
                .eraseToAnyPublisher()),
            for: T.self,
            propertyName: propertyName)
    }

    private var anyPublisher: AnyPublisher<Value, Never> {
        // A crash here indicated your container class is not descending from InjectableContainer
        (InjectedValues.switchToLatests[
            key(T.self, AnyIdentifiablePublisher<AnyPublisher<Value, Never>>.self, propertyName: propertyName)
            // swiftlint:disable:next force_cast
        ] as! AnyIdentifiablePublisher<AnyPublisher<Value, Never>>).eraseToAnyPublisher()
    }

    /// Published Value
    @available(*, unavailable, message: "@PassThroughPublisher is only available on properties of classes")
    public var wrappedValue: PassThroughPublisher<Value, T> {
        self
    }

    /// Subscript to allow classes to access the wrappedValue
    public static subscript<EnclosingContainer: InjectableContainer>(
        _enclosingInstance object: EnclosingContainer,
        wrapped wrappedKeyPath: KeyPath<EnclosingContainer, PassThroughPublisher<Value, T>>,
        storage storageKeyPath: KeyPath<EnclosingContainer, PassThroughPublisher<Value, T>>
    ) -> PassThroughPublisher<Value, T> {
        object[keyPath: storageKeyPath]
    }

    /// Publishes a new value
    public func send(_ value: Value) {
        publisher.send(value)
    }

    /// Initializes the ValuePublisher
    public init() { }

    /// Return the actual publisher to allow us to send values to the publisher and also subscribe to it using $xxx
    public var projectedValue: AnyPublisher<Value, Never> {
        anyPublisher
    }
}

private protocol AnyIdentifiablePublisherProtocol: Publisher, Identifiable, Equatable {}

/// Class to make any Publisher Identifiable.
public final class AnyIdentifiablePublisher<P: Publisher>: AnyIdentifiablePublisherProtocol {
    /// The Output type of the original publisher
    public typealias Output = P.Output
    /// The Failure type of the original publisher
    public typealias Failure = P.Failure

    /// Identifier of the publisher
    public var id = UUID()

    /// Conformance to equatable
    public static func == (lhs: AnyIdentifiablePublisher<P>, rhs: AnyIdentifiablePublisher<P>) -> Bool {
        lhs.id == rhs.id
    }

    /// Attaches the specified subscriber to this publisher.
    /// - Parameter subscriber: The subscriber to attach to this Publisher, after which it can receive values.
    public func receive<S>(subscriber: S) where S: Subscriber, P.Failure == S.Failure, P.Output == S.Input {
        publisher.receive(subscriber: subscriber)
    }

    /// The original publisher
    public let publisher: P

    /// Initializes the AnyIdentifiablePublisher by passing the original publisher as a parameter.
    public init(_ value: P) {
        self.publisher = value
    }

    /// Erase to any publisher to original publisher.
    public func eraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        guard let publisher = publisher as? AnyPublisher<Output, Failure> else {
            return publisher.eraseToAnyPublisher()
        }

        return publisher
    }
}

///  Property wrapper for injected object that are optional.
///  This is useful for things like GCS, Share,... since some clients might not want to use them.
@propertyWrapper
public final class InjectedOrNil<T> where T: ExpressibleByNilLiteral {

    var defaultValue: T = nil

    /// Published Value
    public var wrappedValue: T {
        InjectedValues[T.self] ?? defaultValue
    }

    /// Required Init for property wrapper.
    public init() {}
}
