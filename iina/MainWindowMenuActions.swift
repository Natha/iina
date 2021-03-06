//
//  MainWindowMenuActions.swift
//  iina
//
//  Created by lhc on 25/12/2016.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

// MARK: - Menu Actions

extension MainWindowController {

  @IBAction func menuTogglePause(_ sender: NSMenuItem) {
    if sender.title == "Play" {
      playerCore.togglePause(false)
      sender.title = "Pause"
    } else {
      playerCore.togglePause(true)
      sender.title = "Play"
    }
  }

  @IBAction func menuStop(_ sender: NSMenuItem) {
    // FIXME: handle stop
    playerCore.stop()
    displayOSD(.stop)
  }

  @IBAction func menuStep(_ sender: NSMenuItem) {
    if sender.tag == 0 { // -> 5s
      playerCore.seek(relativeSecond: 5, option: .relative)
    } else if sender.tag == 1 { // <- 5s
      playerCore.seek(relativeSecond: -5, option: .relative)
    }
  }

  @IBAction func menuStepFrame(_ sender: NSMenuItem) {
    if !playerCore.info.isPaused {
      playerCore.togglePause(true)
    }
    if sender.tag == 0 { // -> 1f
      playerCore.frameStep(backwards: false)
    } else if sender.tag == 1 { // <- 1f
      playerCore.frameStep(backwards: true)
    }
  }


  @IBAction func menuJumpToBegin(_ sender: NSMenuItem) {
    playerCore.seek(absoluteSecond: 0)
  }

  @IBAction func menuJumpTo(_ sender: NSMenuItem) {
    let _ = Utility.quickPromptPanel(messageText: "Jump to:", informativeText: "Example: 20:35") { input in
      if let vt = VideoTime(input) {
        self.playerCore.seek(absoluteSecond: Double(vt.second))
      }
    }
  }

  @IBAction func menuSnapshot(_ sender: NSMenuItem) {
    playerCore.screenShot()
    displayOSD(.screenShot)
  }

  @IBAction func menuABLoop(_ sender: NSMenuItem) {
    playerCore.abLoop()
    displayOSD(.abLoop(playerCore.info.abLoopStatus))
  }

  @IBAction func menuPlaylistItem(_ sender: NSMenuItem) {
    let index = sender.tag
    playerCore.playFileInPlaylist(index)
  }

  @IBAction func menuShowPlaylistPanel(_ sender: NSMenuItem) {
    playlistView.pleaseSwitchToTab(.playlist)
    playlistButtonAction(sender)
  }

  @IBAction func menuShowChaptersPanel(_ sender: NSMenuItem) {
    playlistView.pleaseSwitchToTab(.chapters)
    playlistButtonAction(sender)
  }

  @IBAction func menuChapterSwitch(_ sender: NSMenuItem) {
    let index = sender.tag
    playerCore.playChapter(index)
    let chapter = playerCore.info.chapters[index]
    displayOSD(.chapter(chapter.title))
  }

  @IBAction func menuShowVideoQuickSettings(_ sender: NSMenuItem) {
    quickSettingView.pleaseSwitchToTab(.video)
    settingsButtonAction(sender)
  }

  @IBAction func menuShowAudioQuickSettings(_ sender: NSMenuItem) {
    quickSettingView.pleaseSwitchToTab(.audio)
    settingsButtonAction(sender)
  }

  @IBAction func menuShowSubQuickSettings(_ sender: NSMenuItem) {
    quickSettingView.pleaseSwitchToTab(.sub)
    settingsButtonAction(sender)
  }

  @IBAction func menuChangeTrack(_ sender: NSMenuItem) {
    if let trackObj = sender.representedObject as? MPVTrack {
      playerCore.setTrack(trackObj.id, forType: trackObj.type)
    }
  }

  @IBAction func menuChangeAspect(_ sender: NSMenuItem) {
    if let aspectStr = sender.representedObject as? String {
      playerCore.setVideoAspect(aspectStr)
      displayOSD(.aspect(aspectStr))
    } else {
      Utility.log("Unknown aspect in menuChangeAspect(): \(sender.representedObject)")
    }
  }

  @IBAction func menuChangeCrop(_ sender: NSMenuItem) {
    if let cropStr = sender.representedObject as? String {
      playerCore.setCrop(fromString: cropStr)
    } else {
      Utility.log("sender.representedObject is not a string in menuChangeCrop()")
    }
  }

  @IBAction func menuChangeRotation(_ sender: NSMenuItem) {
    if let rotationInt = sender.representedObject as? Int {
      playerCore.setVideoRotate(rotationInt)
    }
  }

  @IBAction func menuToggleFlip(_ sender: NSMenuItem) {
    if playerCore.info.flipFilter == nil {
      playerCore.setFlip(true)
    } else {
      playerCore.setFlip(false)
    }
  }

  @IBAction func menuToggleMirror(_ sender: NSMenuItem) {
    if playerCore.info.mirrorFilter == nil {
      playerCore.setMirror(true)
    } else {
      playerCore.setMirror(false)
    }
  }

  @IBAction func menuToggleDeinterlace(_ sender: NSMenuItem) {
    playerCore.toggleDeinterlace(sender.state != NSOnState)
  }

  @IBAction func menuChangeWindowSize(_ sender: NSMenuItem) {
    // -1: normal(non-retina), same as 1 when on non-retina screen
    //  0: half
    //  1: normal
    //  2: double
    //  3: fit screen
    //  10: smaller size
    //  11: bigger size
    let size = sender.tag
    guard let w = window, let vw = playerCore.info.displayWidth, let vh = playerCore.info.displayHeight else { return }

    var retinaSize = w.convertFromBacking(NSMakeRect(w.frame.origin.x, w.frame.origin.y, CGFloat(vw), CGFloat(vh)))
    let screenFrame = NSScreen.main()!.visibleFrame
    let newFrame: NSRect
    let sizeMap: [CGFloat] = [0.5, 1, 2]
    let scaleStep: CGFloat = 25

    switch size {
    // scale
    case 0, 1, 2:
      retinaSize.size.width *= sizeMap[size]
      retinaSize.size.height *= sizeMap[size]
      if retinaSize.size.width > screenFrame.size.width || retinaSize.size.height > screenFrame.size.height {
        newFrame = w.frame.centeredResize(to: w.frame.size.shrink(toSize: screenFrame.size)).makeLocate(in: screenFrame)
      } else {
        newFrame = w.frame.centeredResize(to: retinaSize.size).makeLocate(in: screenFrame)
      }
    // fit screen
    case 3:
      w.center()
      newFrame = w.frame.centeredResize(to: w.frame.size.shrink(toSize: screenFrame.size))
    // bigger size
    case 10, 11:
      let newWidth = w.frame.width + scaleStep * (size == 10 ? -1 : 1)
      let newHeight = newWidth / (w.aspectRatio.width / w.aspectRatio.height)
      newFrame = w.frame.centeredResize(to: NSSize(width: newWidth, height: newHeight))
    default:
      return
    }

    w.setFrame(newFrame, display: true, animate: true)
  }

  @IBAction func menuAlwaysOnTop(_ sender: NSMenuItem) {
    playerCore.info.isAlwaysOntop = !playerCore.info.isAlwaysOntop
    setWindowFloatingOntop(playerCore.info.isAlwaysOntop)
  }

  @IBAction func menuToggleFullScreen(_ sender: NSMenuItem) {
    toggleWindowFullScreen()
    sender.title = isInFullScreen ? Constants.String.exitFullScreen : Constants.String.fullScreen
  }

  @IBAction func menuChangeVolume(_ sender: NSMenuItem) {
    if let volumeDelta = sender.representedObject as? Int {
      let newVolume = volumeDelta + playerCore.info.volume
      playerCore.setVolume(newVolume)
    } else {
      Utility.log("sender.representedObject is not int in menuChangeVolume()")
    }
  }

  @IBAction func menuToggleMute(_ sender: NSMenuItem) {
    playerCore.toogleMute(nil)
  }

  @IBAction func menuChangeAudioDelay(_ sender: NSMenuItem) {
    if let delayDelta = sender.representedObject as? Double {
      let newDelay = playerCore.info.audioDelay + delayDelta
      playerCore.setAudioDelay(newDelay)
    } else {
      Utility.log("sender.representedObject is not Double in menuChangeAudioDelay()")
    }
  }

  @IBAction func menuResetAudioDelay(_ sender: NSMenuItem) {
    playerCore.setAudioDelay(0)
  }

  @IBAction func menuLoadExternalSub(_ sender: NSMenuItem) {
    let _ = Utility.quickOpenPanel(title: "Load external subtitle file", isDir: false) { url in
      self.playerCore.loadExternalSubFile(url)
    }
  }

  @IBAction func menuChangeSubDelay(_ sender: NSMenuItem) {
    if let delayDelta = sender.representedObject as? Double {
      let newDelay = playerCore.info.subDelay + delayDelta
      playerCore.setSubDelay(newDelay)
    } else {
      Utility.log("sender.representedObject is not Double in menuChangeSubDelay()")
    }
  }

  @IBAction func menuChangeSubScale(_ sender: NSMenuItem) {
    if sender.tag == 0 {
      playerCore.setSubScale(1)
      return
    }
    // FIXME: better refactor this part
    let amount = sender.tag > 0 ? 0.1 : -0.1
    let currentScale = playerCore.mpvController.getDouble(MPVOption.Subtitles.subScale)
    let displayValue = currentScale >= 1 ? currentScale : -1/currentScale
    let truncated = round(displayValue * 100) / 100
    var newTruncated = truncated + amount
    // range for this value should be (~, -1), (1, ~)
    if newTruncated > 0 && newTruncated < 1 || newTruncated > -1 && newTruncated < 0 {
      newTruncated = -truncated + amount
    }
    playerCore.setSubScale(abs(newTruncated > 0 ? newTruncated : 1 / newTruncated))
  }

  @IBAction func menuResetSubDelay(_ sender: NSMenuItem) {
    playerCore.setSubDelay(0)
  }

  @IBAction func menuSetSubEncoding(_ sender: NSMenuItem) {
    playerCore.setSubEncoding((sender.representedObject as? String) ?? "auto")
  }

  @IBAction func menuSubFont(_ sender: NSMenuItem) {
    Utility.quickFontPickerWindow() {
      self.playerCore.setSubFont($0 ?? "")
    }

  }

  @IBAction func menuFindOnlineSub(_ sender: NSMenuItem) {
    guard let url = playerCore.info.currentURL else { return }
    displayOSD(.startFindingSub)
    OnlineSubtitle.getSub(forFile: url) { subtitles in
      // send osd in main thread
      self.playerCore.sendOSD(.foundSub(subtitles.count))
      // download them
      for sub in subtitles {
        sub.download { url in
          Utility.log("Saved subtitle to \(url.path)")
          self.playerCore.loadExternalSubFile(url)
          self.playerCore.sendOSD(.downloadedSub)
        }
      }
    }
  }

  @IBAction func menuShowInspector(_ sender: AnyObject) {
    let inspector = (NSApp.delegate as! AppDelegate).inspector
    inspector.showWindow(self)
    inspector.updateInfo()
  }

}
