//
//  File.swift
//  
//
//  Created by Douglas Pedley on 11/26/20.
//

import Foundation

extension Chess.Robot {
    public class PlaybackBot: Chess.Player {
        var moveStrings: [String] = []
        var currentMove = 0
        let responseDelay: TimeInterval
        required init(firstName: String, lastName: String, side: Chess.Side, moves: [String], responseDelay: TimeInterval) {
            self.responseDelay = responseDelay
            moveStrings.append(contentsOf: moves)
            super.init(side: side, matchLength: nil)
            self.firstName = firstName
            self.lastName = lastName
        }
        
        override func isBot() -> Bool {
            return true
        }
        
        override func prepareForGame() {
            currentMove = 0
        }
        
        override func turnUpdate(game: Chess.Game) {
            // This bot only acts on it's own turn, no eval during opponents move time
            guard game.board.playingSide == side else { return }
            guard let delegate = game.delegate else {
                fatalError("Cannot run a game turn without a game delegate.")
            }
            weak var weakSelf = self
            weak var weakDelegate = delegate
            Thread.detachNewThread {
                if let responseDelay = weakSelf?.responseDelay {
                    Thread.sleep(forTimeInterval: responseDelay)
                }
                // Notice we don't strongify until after the sleep. Otherwise we'd be holding onto self
                guard let self = weakSelf, let delegate = weakDelegate,
                      self.currentMove<self.moveStrings.count else { return }
                let moveString = self.moveStrings[self.currentMove]
                guard let move = self.side.twoSquareMove(fromString: moveString) else {
                    return
                }
                
                // Make yer move.
                delegate.send(.makeMove(move: move))
                
                // Let's update our move index
                self.currentMove += 1
            }
        }
    }
}

extension Chess {
    public class HumanPlayer: Player {
        static let minimalHumanTimeinterval: TimeInterval = 0.1
        public var chessBestMoveCallback: Chess_TurnCallback?
        public var initialPositionTapped: Chess.Position?
        public var moveAttempt: Chess.Move? {
            didSet {
                if let move = moveAttempt, let callback = chessBestMoveCallback {
                    callback(move)
                    moveAttempt = nil
                    initialPositionTapped = nil
                }
            }
        }
        override func isBot() -> Bool {
            return false
        }
        
        override func prepareForGame() {
            // Washes hands
        }
        
        override func timerRanOut() {
            // TODO message human that the game is over.
        }
        
        override func turnUpdate(game: Chess.Game) {
            // TODO, this is probably where we serialize the state of the board for app restarts etc.
            if let move = moveAttempt {
                // Premove baby!
                moveAttempt = nil
                game.delegate?.send(.makeMove(move: move))
            } else {
                weak var weakDelegate = game.delegate
                chessBestMoveCallback = { move in
                    guard let delegate = weakDelegate else { return }
                    delegate.send(.makeMove(move: move))
                }
            }
        }
    }
}
