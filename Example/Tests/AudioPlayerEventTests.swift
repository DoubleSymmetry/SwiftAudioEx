import Quick
import Nimble
import MediaPlayer

@testable import SwiftAudioEx

class AudioPlayerEventTests: QuickSpec {
    
    class EventListener {
        var handleEvent: ((Void)) -> Void = { _ in
            
        }
    }
    
    override func spec() {
        
        describe("An event") {
            var event: AudioPlayer.Event<(Void)>!
            beforeEach {
                event = AudioPlayer.Event()
            }
            
            describe("its invokers") {
                
                context("when adding a listener") {
                    var listener: EventListener!
                    beforeEach {
                        listener = EventListener()
                        event.addListener(listener, listener!.handleEvent)
                    }
                    
                    it("should have one element") {
                        await expect(event.invokers.count).toEventuallyNot(equal(0))
                    }
                    
                    context("then that listener is deinitialized and an an event is emitted") {
                        beforeEach {
                            listener = nil
                            await event.emit(data: ())
                        }
                        
                        it("should remove the invoker") {
                            await expect(event.invokers.count).toEventually(equal(0))
                        }
                        
                    }
                }
                
                context("when adding multiple listeners") {
                    var listeners: [EventListener]!
                    
                    beforeEach {
                        listeners = [0..<15].map {_ in
                            let listener = EventListener()
                            event.addListener(listener, listener.handleEvent)
                            return listener
                        }
                    }
                    
                    it("should have several listeners") {
                        await expect(event.invokers.count).toEventually(equal(listeners.count))
                    }
                    
                    context("then removing one") {
                        beforeEach {
                            event.removeListener(listeners[listeners.count / 2])
                        }
                        
                        it("should have one less invoker") {
                            await expect(event.invokers.count).toEventually(equal(listeners.count - 1))
                        }
                    }
                    
                }
                
            }
        }
        
    }
    
}
