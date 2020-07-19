//
//  Rx.swift
//  simple_mvvm
//
//  Created by mothule on 2020/07/19.
//  Copyright © 2020 mothule. All rights reserved.
//

import Foundation

// イベント
enum Event<Element> {
    case next(Element)
}

// MARK: - Observer(観測者)
protocol ObserverType {
    associatedtype Element
    func on(_ event: Event<Element>)
}
extension ObserverType {
    func onNext(_ element: Element) { self.on(.next(element)) }
}

// MARK: - Observable(観測対象)
protocol ObservableConvertibleType {
    associatedtype Element
    
    func asObservable() -> Observable<Element>
}

protocol ObservableType: ObservableConvertibleType {
    func subscribe<Observer: ObserverType>(_ observer: Observer) where Observer.Element == Element
}

class Observable<Element>: ObservableType {
    func subscribe<Observer: ObserverType>(_ observer: Observer) where Observer.Element == Element { fatalError() }
    func asObservable() -> Observable<Element> { self }
}

// MARK: - Observer(観測者) 具現

class ObserverBase<Element>: ObserverType {
    func on(_ event: Event<Element>) {
        switch event {
        case .next: onCore(event)
        }
    }
    func onCore(_ event: Event<Element>) { fatalError() }
}

// 匿名Observer.
// イベント処理をクロージャとして保持・利用する。
class AnonymousObserver<Element>: ObserverBase<Element> {
    typealias EventHandler = (Event<Element>) -> Void
    private let eventHandler: EventHandler
    
    init(_ handler: @escaping EventHandler) {
        eventHandler = handler
    }
    
    override func onCore(_ event: Event<Element>) {
        eventHandler(event)
    }
}

struct AnyObserver<Element>: ObserverType {
    typealias EventHandler = (Event<Element>) -> Void
    private let observer: EventHandler
    
    init(_ handler: @escaping EventHandler) {
        self.observer = handler
    }
    
    init<Observer: ObserverType>(_ observer: Observer) where Observer.Element == Element {
        self.observer = observer.on
    }
    
    func on(_ event: Event<Element>) {
        self.observer(event)
    }
}

// MARK: - Obsavable(観測対象)　具現

extension ObservableType {
    func subscribe(onNext: @escaping (Element) -> Void) {
        let observer = AnonymousObserver<Element> { event in
            switch event {
            case .next(let value):
                onNext(value)
            }
        }
        asObservable().subscribe(observer)
    }
}

class Subject<Element>: Observable<Element>{
    
    var observers: [AnyObserver<Element>] = []
    private(set) var lastValue: Element
    
    init(_ value: Element) {
        self.lastValue = value
    }
    
    override func subscribe<Observer>(_ observer: Observer) where Element == Observer.Element, Observer : ObserverType {
        observers.append(.init(observer))
    }
    
    func onNext(_ value: Element) {
        lastValue = value
        observers.forEach({ $0.onNext(value) })
    }
}


// MARK: - combineLatest

extension ObservableType {
    static func combineLatest<First: ObservableType, Second: ObservableType>
        (_ source1: First, _ source2: Second, resultSelector: @escaping (First.Element, Second.Element) -> Element) -> Observable<Element> {
        return CombineLatest2(
            source1: source1.asObservable(),
            source2: source2.asObservable(),
            resultSelector: resultSelector)
    }
}

// 取り込んだソースを購読しておき、ソースが変化したら、自身が変化したことを告げる
class CombineLatest2<E1, E2, Result>: Observable<Result> {
    var observers: [AnyObserver<Result>] = []
    
    let source1: Observable<E1>
    let source2: Observable<E2>
    var source1Element: E1!
    var source2Element: E2!
    let selector: (E1, E2) -> Result
    
    init(source1: Observable<E1>, source2: Observable<E2>, resultSelector: @escaping (E1, E2) -> Result) {
        self.source1 = source1
        self.source2 = source2
        self.selector = resultSelector
        
        super.init()
        
        self.source1.subscribe(onNext: { [unowned self] value in
            self.source1Element = value
            self.onNextCurrent()
        })
        
        self.source2.subscribe(onNext: { [unowned self] value in
            self.source2Element = value
            self.onNextCurrent()
        })
    }
    
    override func subscribe<Observer>(_ observer: Observer) where Element == Observer.Element, Observer : ObserverType {
        let any = AnyObserver<Result>(observer)
        observers.append(any)
        self.onNextCurrent()
    }
    
    func onNext(_ value: Element) {
        observers.forEach({ $0.onNext(value) })
    }
    
    private func onNextCurrent() {
        if let source1Element = source1Element,
            let source2Element = source2Element {
            let result = selector(source1Element, source2Element)
            onNext(result)
        }
    }
}
