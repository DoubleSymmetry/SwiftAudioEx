import Quick
import Nimble
import AVFoundation

@testable import SwiftAudioEx

class AVPlayerTimeObserverTests: QuickSpec {
  
    override func spec() {
        
        describe("AVPlayerTimeObserver") {
            
            var player: AVPlayer!
            var observer: AVPlayerTimeObserver!

            @MainActor
            @Sendable
            func setAutomaticallyWaitsToMinimizeStalling(for player: AVPlayer, value: Bool) async {
                player.automaticallyWaitsToMinimizeStalling = value
            }

            
            beforeEach {
                let p = AVPlayer()
                player = p
                await setAutomaticallyWaitsToMinimizeStalling(for: p, value: false)
                player.volume = 0
                observer = AVPlayerTimeObserver(periodicObserverTimeInterval: TimeEventFrequency.everyQuarterSecond.getTime())
                observer.player = player
            }
            
            context("has started boundary time observing") {
                
                beforeEach {
                    observer.registerForBoundaryTimeEvents()
                }
                
                it("should have a boundary token") {
                    expect(observer.boundaryTimeStartObserverToken).toNot(beNil())
                }
                
                context("has ended boundary time observing") {
                    
                    beforeEach {
                        observer.unregisterForBoundaryTimeEvents()
                    }
                    
                    it("should have no boundary token") {
                        expect(observer.boundaryTimeStartObserverToken).to(beNil())
                    }
                    
                }
                
            }
            
            context("has started periodic time observing") {
                
                beforeEach {
                    observer.registerForPeriodicTimeEvents()
                }
                
                it("should have a periodic token") {
                    expect(observer.periodicTimeObserverToken).toNot(beNil())
                }
                
                context("ended periodic time observing") {
                    
                    beforeEach {
                        observer.unregisterForPeriodicEvents()
                    }
                    
                    it("should have no periodic token") {
                        expect(observer.periodicTimeObserverToken).to(beNil())
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
