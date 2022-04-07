// ffmpegDemo
//
// Created by ffmpegDemo on 14/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import KDCircularProgress
import mobileffmpeg
import DateHelper

/// This controller will be used for recording sound with lyrics and lyrics will be scrollable based on time
class RecordingWithSoundLyrics: BaseViewController, StoryboardSceneBased, LogDelegate, StatisticsDelegate {
    
    static let sceneStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    // Progress bar
    @IBOutlet weak var progressBar: KDCircularProgress!
    
    // Camera viwe
    @IBOutlet weak var viewMain: UIView!
    
    // Record button
    @IBOutlet weak var btnRecord: UIButton!
    
    // Lyrics view
    @IBOutlet weak var lyricsView: LyricsView!
    
    @IBOutlet weak var lblProgress: UILabel!
    
    // Variables from previous viewcontroller
    var isCameraAudioUse: Bool!
    
    // Audio player
    var player: AVAudioPlayer?
    
    // Audio file duration
    var audioDurationSeconds: Double!
    
    // Camera screen object
    var vc: CameraVC!
    
    // Counter for timer
    var counter = 0.0
    
    // Timer object
    var timer: Timer!
    
    // Lyrics array
    var arrStrLyrics = [String]()
        
    // Video duration
    var durationVideo: Double?

    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set lyrics view properties
        lyricsView.lyricFont = UIFont(name: "BebasNeueBold", size: 21.0)!
        lyricsView.lyricTextColor = .lightGray
        lyricsView.lyricHighlightedFont = UIFont(name: "BebasNeueBold", size: 21.0)!
        lyricsView.lyricHighlightedTextColor = .white
        
        // Set up camera vc
        DispatchQueue.main.async { [weak self] in
            self?.vc = CameraVC(nibName: "CameraVC", bundle: nil)
            self?.vc.isCameraAudioUse = self!.isCameraAudioUse
            
            // Set height or width
            self?.vc.view.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN.bounds.width, height: MAIN_SCREEN.bounds.height)
            self?.viewMain.addSubview(self!.vc.view)
            
            // When tap on start recording then this block will call
            self?.vc.playSoundBlock = {
                DispatchQueue.main.sync {
                    
                    self?.btnRecord.isHidden = true
                    self?.btnRecord.isSelected = true
                    
                    // play song in background
                    self?.playSoundOnRecording()
                    
                    // Play lyrics on camera recording
                    self?.updateLyricsOnScreen()
                    
                }
            }
            
            self?.vc.executeFFMPEGBlock = { [weak self] (cameraVideoPath) in
                
                self?.player?.pause()
                
                if let _ = self?.timer {
                    // Invalidate timer
                    self?.timer.invalidate()
                    self?.timer = nil
                }
                
                // Pause lyrics
                self?.lyricsView.timer.pause()
                
                self?.durationVideo = AVAsset(url: URL(fileURLWithPath: cameraVideoPath)).duration.seconds
                
                // ffmpeg operation
                self?.executeFFMPEG(cameraVideoPath: cameraVideoPath, audioFileName: "AlessoSadSongOfficialMusicVideo", audionFileExten: "mp3", lyricsFileName: "IMG_0614", lyricsFileExten: "srt")
            }
        }
        
        //  Delegates Log and Statistics
        DispatchQueue.main.async {
            MobileFFmpegConfig.setLogDelegate(self)
            MobileFFmpegConfig.setStatisticsDelegate(self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get file lenght
        audioDurationSeconds = Utility.sharedUtility.getFileLenght(fileName: "AlessoSadSongOfficialMusicVideo", exten: "mp3")
        print(audioDurationSeconds ?? 0.0)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
    }
    
    
    /// Action to start and stop video recording
    /// - Parameter sender: Button object
    @IBAction func btnRecordingClick(_ sender: UIButton) {
        vc.toggleMovieRecording(vc.recordButton)
    }
    
    
    func logCallback(_ executionId: Int, _ level: Int32, _ message: String!) {
        print(message ?? "")
    }
    
    func statisticsCallback(_ statistics: Statistics!) {
        if statistics == nil {
            return
        }
        
        // Will get video duration , like how much processing is completed
        let timeInMilliseconds = statistics?.getTime() ?? 0
        if timeInMilliseconds > 0 {
            
            print((Int(timeInMilliseconds) / 1000 * (100 / Int(self.durationVideo ?? 0.0))))
        }
    }
}

extension RecordingWithSoundLyrics {
    
    /// Update lyrics on screen UI
    func updateLyricsOnScreen() {
        
        // Get local srt file
        let pathSRT = MAIN_BUNDLE.path(forResource: "IMG_0614", ofType: "srt") ?? ""
        
        do {
            let lyricsString = try String(contentsOfFile: pathSRT).replacingOccurrences(of: "\r", with: "")
            
            // Formatted srt content into .lrc content
            let srtContent = SRT(content: lyricsString)
            let segments = srtContent.segments
            _ = segments.filter { subtitleSegment in
                self.arrStrLyrics.append("[\(subtitleSegment.startTime)]\(subtitleSegment.contents.joined(separator: ", "))")
                return true
            }
            
            // Set lyrics in lyricsview
            lyricsView.lyrics = self.arrStrLyrics.joined(separator: "\n")
            
            // Play
            lyricsView.timer.play()
            
        } catch {
            print(error)
        }
    }
    
    
    /// FFMpeg operation will be performed in this function
    /// - Parameters:
    ///   - cameraVideoPath: Camera recodrded video path
    ///   - audioFileName: Audio file name
    ///   - audionFileExten: Audio file extension
    ///   - lyricsFileName: Lyrics file name
    ///   - lyricsFileExten: Lyrics file extension
    func executeFFMPEG(cameraVideoPath: String, audioFileName: String, audionFileExten: String, lyricsFileName: String, lyricsFileExten: String) {
        
        // Execute ffmeg command
        
        // Get local audio file
        let pathAudio = MAIN_BUNDLE.path(forResource: audioFileName, ofType: audionFileExten)
        
        // Get local srt file
        let pathSRT = MAIN_BUNDLE.path(forResource: lyricsFileName, ofType: lyricsFileExten) ?? ""
        
        // Get current date and time
        let currentDateTime = Date().toString(format: .custom("hh_mm_ss"))
        
        // Set destination path
        let distinationPath = FileHelper.getDocumentDirectory()?.appending("\(currentDateTime ?? "").mp4")
        
        let fontNameMapping = ["MyFontName" : "BebasNeueBold"]
        MobileFFmpegConfig.setFontDirectory(MAIN_BUNDLE.resourcePath, with: fontNameMapping)
        MobileFFmpegConfig.ignoreSignal(SIGXCPU)
        let strCompleteCommand = String(format: "-hide_banner -i %@ -i %@ -vf subtitles=%@:force_style='FontName=MyFontName' -shortest -preset ultrafast -y %@", cameraVideoPath, pathAudio!, pathSRT, distinationPath!)
        print(strCompleteCommand)
        
        // Result of ffmpeg command
        let result = MobileFFmpeg.execute(strCompleteCommand)
        if result != RETURN_CODE_SUCCESS {
            
            self.showAlertError()
        } else if result == RETURN_CODE_CANCEL {
            
            self.showAlertCancel()
        } else {
            
            self.showAlertSuccess {
                self.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
    /// Play audio file
    func playSoundOnRecording() {
        
        DispatchQueue.main.async {
            self.btnRecord.isHidden = true
            self.btnRecord.isSelected = true
            
            // Play mp3 sound
            self.playSound(fileName: "AlessoSadSongOfficialMusicVideo", exten: "mp3")
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] (timer) in
                self.counter += 1.0
                
                // On which time by default camera will stop
                //                if self.counter == 30.0 {
                //                    self.btnRecord.isEnabled = false
                //                    vc.toggleMovieRecording(vc.recordButton)
                //                }
                
                // Min. duration on which stop button will show
                if self.counter == 5.0 {
                    self.btnRecord.isHidden = false
                }
            }
        }
    }
    
    /// Progress will display based on sound lenght
    /// - Parameter length: Audio file length
    func progressBarTracking(length: Double) {
        DispatchQueue.main.async {
            self.progressBar.startAngle = -90
            self.progressBar.progressThickness = 0.1
            self.progressBar.trackThickness = 0.1
            self.progressBar.clockwise = true
            self.progressBar.roundedCorners = true
            self.progressBar.trackColor = .white
            self.progressBar.progressColors = [.red]
            
            self.progressBar.animate(fromAngle: 0, toAngle: 360, duration: length) { completed in
                if completed {
                    print("animation stopped, completed")
                } else {
                    print("animation stopped, was interrupted")
                }
            }
            
        }
    }
    
    /// Play audio sound
    /// - Parameters:
    ///   - fileName: Audio file name
    ///   - exten: Audio file extension
    func playSound(fileName: String, exten: String) {
        // Start tracking of audio which will run during video recording
        progressBarTracking(length: audioDurationSeconds ?? 0.0)
        
        guard let url = MAIN_BUNDLE.url(forResource: fileName, withExtension: exten) else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

