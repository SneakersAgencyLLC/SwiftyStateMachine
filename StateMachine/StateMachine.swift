//
//  StateMachine.swift
//  StateMachine
//
//  Created by Maciej Konieczny on 2015-03-24.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

public protocol DOTLabel {
    var DOTLabel: String { get }
}


public protocol StateMachineStructureType {
    typealias State
    typealias Event
    typealias Subject

    var initialState: State { get }
    var transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)? { get }
}


public struct StateMachineStructure<A, B, C>: StateMachineStructureType {
    typealias State = A
    typealias Event = B
    typealias Subject = C

    public let initialState: State
    public let transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)?

    public init(initialState: State, transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
    }
}


public struct GraphableStateMachineStructure<A: DOTLabel, B: DOTLabel, C>: StateMachineStructureType {
    typealias State = A
    typealias Event = B
    typealias Subject = C

    public let initialState: State
    public let transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)?
    public let DOTDigraph: String

    public init(graphStates: [State], graphEvents: [Event], graphSubject: Subject, initialState: State, transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
        self.DOTDigraph = GraphableStateMachineStructure.DOTDigraphGivenTransitionLogic(transitionLogic, states: graphStates, events: graphEvents, subject: graphSubject)
    }

    private static func DOTDigraphGivenTransitionLogic(transitionLogic: (State, Event, Subject, (Event) -> ()) -> (State, (() -> ())?)?, states: [State], events: [Event], subject: Subject) -> String {
        var stateIndexesByLabel: [String: Int] = [:]
        var digraph = "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n"

        for (i, state) in enumerate(states) {
            let index = i + 1
            let label = state.DOTLabel
            stateIndexesByLabel[label] = index

            digraph += "    \(index) [label=\"\(label)\"]\n"
        }

        digraph += "\n"

        for fromState in states {
            for event in events {
                if let (toState, _) = transitionLogic(fromState, event, subject, { _ in }) {
                    let fromIndex = stateIndexesByLabel[fromState.DOTLabel]!
                    let toIndex = stateIndexesByLabel[toState.DOTLabel]!

                    digraph += "    \(fromIndex) -> \(toIndex) [label=\"\(event.DOTLabel)\"]\n"
                }
            }
        }

        digraph += "}"

        return digraph
    }
}


public struct StateMachine<T: StateMachineStructureType> {
    public var state: T.State
    public var didTransitionCallback: ((T.State, T.Event, T.State) -> ())?

    private let structure: T
    private let subject: T.Subject

    public init(structure: T, subject: T.Subject) {
        self.state = structure.initialState
        self.structure = structure
        self.subject = subject
    }

    public mutating func handleEvent(event: T.Event) {
        if let (newState, transition) = structure.transitionLogic(state, event, subject, self.handleEvent) {
            let oldState = state
            state = newState
            transition?()
            didTransitionCallback?(oldState, event, newState)
        }
    }
}
