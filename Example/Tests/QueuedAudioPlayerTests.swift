import Quick
import Nimble

@testable import SwiftAudioEx

extension QueuedAudioPlayer {
    class SeekEventListener {
        var eventResult: (Int, Bool) = (-1, false)
        func handleEvent(seconds: Int, didFinish: Bool) { eventResult = (seconds, didFinish) }
    }

    func seekWithExpectation(to time: Double) {
        let eventListener = SeekEventListener()
        event.seek.addListener(eventListener, eventListener.handleEvent)

        seek(to: time)
        expect(eventListener.eventResult).toEventually(equal((0, true)))
    }
}

class QueuedAudioPlayerTests: QuickSpec {
    override func spec() {
        describe("A QueuedAudioPlayer") {
            var audioPlayer: QueuedAudioPlayer!
            beforeEach {
                audioPlayer = QueuedAudioPlayer()
                audioPlayer.volume = 0.0
            }
            describe("its current item") {
                it("should be nil") {
                    expect(audioPlayer.currentItem).to(beNil())
                }

                context("when adding one item") {
                    var item: AudioItem!
                    beforeEach {
                        item = ShortSource.getAudioItem()
                        try? audioPlayer.add(item: item, playWhenReady: false)
                    }
                    it("should not be nil") {
                        expect(audioPlayer.currentItem).toNot(beNil())
                    }

                    context("then loading a new item") {
                        beforeEach {
                            try? audioPlayer.load(item: Source.getAudioItem(), playWhenReady: false)
                        }

                        it("should have replaced the item") {
                            expect(audioPlayer.currentItem?.getSourceUrl()).toNot(equal(item.getSourceUrl()))
                        }
                    }
                }

                context("when adding multiple items") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()], playWhenReady: false)
                    }
                    it("should not be nil") {
                        expect(audioPlayer.currentItem).toNot(beNil())
                    }
                }
            }

            describe("its next items") {
                it("should be empty") {
                    expect(audioPlayer.nextItems.count).to(equal(0))
                }

                context("when adding 2 items") {
                    beforeEach {
                        try? audioPlayer.add(items: [Source.getAudioItem(), Source.getAudioItem()])
                    }
                    it("should contain 1 item") {
                        expect(audioPlayer.nextItems.count).to(equal(1))
                    }

                    context("then calling next()") {
                        beforeEach {
                            try? audioPlayer.next()
                        }
                        it("should contain 0 items") {
                            expect(audioPlayer.nextItems.count).to(equal(0))
                        }

                        context("then calling previous()") {
                            beforeEach {
                                try? audioPlayer.previous()
                            }
                            it("should contain 1 item") {
                                expect(audioPlayer.nextItems.count).to(equal(1))
                            }
                        }
                    }

                    context("then removing one item") {
                        beforeEach {
                            try? audioPlayer.removeItem(at: 1)
                        }

                        it("should be empty") {
                            expect(audioPlayer.nextItems.count).to(equal(0))
                        }
                    }

                    context("then jumping to the last item") {
                        beforeEach {
                            try? audioPlayer.jumpToItem(atIndex: 1)
                        }
                        it("should be empty") {
                            expect(audioPlayer.nextItems.count).to(equal(0))
                        }
                    }

                    context("then removing upcoming items") {
                        beforeEach {
                            audioPlayer.removeUpcomingItems()
                        }

                        it("should be empty") {
                            expect(audioPlayer.nextItems.count).to(equal(0))
                        }
                    }

                    context("then stopping") {
                        beforeEach {
                            audioPlayer.stop()
                        }

                        it("should be empty") {
                            expect(audioPlayer.nextItems.count).to(equal(0))
                        }
                    }
                }
            }

            describe("its previous items") {
                it("should be empty") {
                    expect(audioPlayer.previousItems.count).to(equal(0))
                }

                context("when adding 2 items") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()])
                    }

                    it("should be empty") {
                        expect(audioPlayer.previousItems.count).to(equal(0))
                    }

                    context("then calling next()") {
                        beforeEach {
                            try? audioPlayer.next()
                        }
                        it("should contain one item") {
                            expect(audioPlayer.previousItems.count).to(equal(1))
                        }
                    }

                    context("then removing all previous items") {
                        beforeEach {
                            audioPlayer.removePreviousItems()
                        }

                        it("should be empty") {
                            expect(audioPlayer.previousItems.count).to(equal(0))
                        }
                    }

                    context("then stopping") {
                        beforeEach {
                            audioPlayer.stop()
                        }

                        it("should be empty") {
                            expect(audioPlayer.previousItems.count).to(equal(0))
                        }
                    }

                }
            }

            describe("onNext") {
                context("player was playing") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()])
                    }

                    context("then calling next()") {
                        beforeEach {
                            try? audioPlayer.next()
                        }

                        it("should go to next item and play") {
                            expect(audioPlayer.nextItems.count).toEventually(equal(0))
                            expect(audioPlayer.currentIndex).toEventually(equal(1))
                            expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                        }
                    }
                }
                context("player was paused") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()])
                        audioPlayer.pause()

                    }

                    context("then calling next()") {
                        beforeEach {
                            try? audioPlayer.next()
                        }

                        it("should go to next item and not play") {
                            expect(audioPlayer.nextItems.count).toEventually(equal(0))
                            expect(audioPlayer.currentIndex).toEventually(equal(1))
                            expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.ready))
                        }
                    }
                }
            }

            describe("onPrevious") {
                context("player was playing") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()], playWhenReady: true)
                        try? audioPlayer.next()
                    }

                    context("then calling previous()") {
                        beforeEach {
                            try? audioPlayer.previous()
                        }

                        it("should go to previous item and play") {
                            expect(audioPlayer.nextItems.count).toEventually(equal(1))
                            expect(audioPlayer.previousItems.count).toEventually(equal(0))
                            expect(audioPlayer.currentIndex).toEventually(equal(0))
                            expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                        }
                    }
                }
                context("player was paused") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()])
                        try? audioPlayer.next()
                        audioPlayer.pause()

                    }

                    context("then calling previous()") {
                        beforeEach {
                            try? audioPlayer.previous()
                        }

                        it("should go to previous item and not play") {
                            expect(audioPlayer.nextItems.count).toEventually(equal(1))
                            expect(audioPlayer.previousItems.count).toEventually(equal(0))
                            expect(audioPlayer.currentIndex).toEventually(equal(0))
                            expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.ready))
                        }
                    }
                }
            }

            class TestEventListener {
                var eventResult: (Int?, Int?) = (-1, -1)
                func handleEvent(previousIndex: Int?, nextIndex: Int?) { eventResult = (previousIndex, nextIndex) }
            }

            describe("its repeat mode") {
                context("when adding 2 items") {
                    beforeEach {
                        try? audioPlayer.add(items: [ShortSource.getAudioItem(), ShortSource.getAudioItem()], playWhenReady: true)
                    }

                    context("then setting repeat mode off") {
                        beforeEach {
                            audioPlayer.repeatMode = .off
                        }

                        context("allow playback to end normally") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should move to next item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.nextItems.count).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(1))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 1)))
                            }

                            context("allow playback to end again") {
                                beforeEach {
                                    audioPlayer.seekWithExpectation(to: 0.0682)
                                }

                                it("should stop playback normally") {
                                    let eventListener = TestEventListener()
                                    audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                    expect(audioPlayer.nextItems.count).toEventually(equal(0))
                                    expect(audioPlayer.currentIndex).toEventually(equal(1))
                                    expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.paused))
                                    expect(eventListener.eventResult).toEventually(equal((1, nil)))
                                }
                            }
                        }

                        context("then calling next()") {
                            it("should move to next item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                try? audioPlayer.next()
                                expect(audioPlayer.nextItems.count).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(1))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 1)))
                            }

                            context("then calling next() again") {
                                it("should fail") {
                                    try? audioPlayer.next()
                                    expect(try audioPlayer.next()).to(throwError())
                                }
                            }
                        }
                    }

                    context("then setting repeat mode track") {
                        beforeEach {
                            audioPlayer.repeatMode = .track
                        }

                        context("allow playback to end") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should restart current item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.currentTime).toEventually(equal(0))
                                expect(audioPlayer.nextItems.count).toEventually(equal(1))
                                expect(audioPlayer.currentIndex).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 0)))
                            }
                        }

                        context("then calling next()") {
                            it("should move to next item and should play") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                try? audioPlayer.next()
                                expect(audioPlayer.nextItems.count).to(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 1)))
                            }
                        }
                    }

                    context("then setting repeat mode queue") {
                        beforeEach {
                            audioPlayer.repeatMode = .queue
                        }

                        context("allow playback to end") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should move to next item and should play") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.nextItems.count).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(1))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 1)))
                            }

                            context("allow playback to end again") {
                                beforeEach {
                                    audioPlayer.seekWithExpectation(to: 0.0682)
                                }

                                it("should move to first track and should play") {
                                    let eventListener = TestEventListener()
                                    audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                    expect(audioPlayer.nextItems.count).toEventually(equal(1))
                                    expect(audioPlayer.currentIndex).toEventually(equal(0))
                                    expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                    expect(eventListener.eventResult).toEventually(equal((1, 0)))
                                }
                            }
                        }

                        context("then calling next()") {
                            it("should move to next item and should play") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                try? audioPlayer.next()
                                expect(audioPlayer.nextItems.count).to(equal(0))
                                expect(audioPlayer.currentIndex).to(equal(1))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 1)))
                            }

                            context("then calling next() again") {
                                beforeEach {
                                    try? audioPlayer.next()
                                }

                                it("should move to first track and should play") {
                                    let eventListener = TestEventListener()
                                    audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                    try? audioPlayer.next()
                                    expect(audioPlayer.nextItems.count).to(equal(1))
                                    expect(audioPlayer.currentIndex).to(equal(0))
                                    expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                    expect(eventListener.eventResult).toEventually(equal((1, 0)))
                                }
                            }
                        }
                    }
                }

                context("when adding 1 items") {
                    beforeEach {
                        try? audioPlayer.add(item: ShortSource.getAudioItem(), playWhenReady: true)
                    }

                    context("then setting repeat mode off") {
                        beforeEach {
                            audioPlayer.repeatMode = .off
                        }

                        context("allow playback to end normally") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should stop playback normally") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.nextItems.count).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.paused))
                                expect(eventListener.eventResult).toEventually(equal((0, nil)))
                            }
                        }

                        context("then calling next()") {
                            it("should fail") {
                                try? audioPlayer.next()
                                expect(try audioPlayer.next()).to(throwError())
                            }
                        }
                    }

                    context("then setting repeat mode track") {
                        beforeEach {
                            audioPlayer.repeatMode = .track
                        }

                        context("allow playback to end") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should restart current item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.currentTime).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 0)))
                            }
                        }

                        context("then calling next()") {
                            it("should restart current item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.currentTime).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 0)))
                            }
                        }
                    }

                    context("then setting repeat mode queue") {
                        beforeEach {
                            audioPlayer.repeatMode = .queue
                        }

                        context("allow playback to end") {
                            beforeEach {
                                audioPlayer.seekWithExpectation(to: 0.0682)
                            }

                            it("should restart current item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                expect(audioPlayer.currentTime).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 0)))
                            }
                        }

                        context("then calling next()") {
                            it("should restart current item") {
                                let eventListener = TestEventListener()
                                audioPlayer.event.queueIndex.addListener(eventListener, eventListener.handleEvent)

                                // workaround: seek not to beggining, for 0 expecations to correctly fail if necessary.
                                audioPlayer.seekWithExpectation(to: 0.05)
                                try? audioPlayer.next()
                                expect(audioPlayer.currentTime).toEventually(equal(0))
                                expect(audioPlayer.currentIndex).toEventually(equal(0))
                                expect(audioPlayer.playerState).toEventually(equal(AudioPlayerState.playing))
                                expect(eventListener.eventResult).toEventually(equal((0, 0)))
                            }
                        }
                    }
                }
            }
        }
    }
}
