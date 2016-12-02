//
//  ViewController.swift
//  GloryDays
//
//  Created by Juan Manuel Jimenez Sanchez on 28/11/16.
//  Copyright © 2016 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit

import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func askForPermissions(_ sender: UIButton) {
        self.askForPhotosPermissions()
    }

    func askForPhotosPermissions() {
        //Se añade [unowned self] para poder referenciar este bloque de código
        PHPhotoLibrary.requestAuthorization { [unowned self] (authStatus) in
            //Como los bloques de completación suelen ejecutarse en un hilo secundario y esto necesitamos 
            //ejecutarlo en el hilo principal, entonces lo enviamos allí con DispatchQueue.main.async
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.askForRecordPermissions()
                } else {
                    self.infoLabel.text = "Nos has denegado el permiso de fotos. Por favor, activalo en los ajustes de tu dispositivo para continuar."
                }
            }
        }
    }
    
    func askForRecordPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] (allowed) in
            DispatchQueue.main.async {
                if allowed {
                    self.askForTranscriptionPermissions()
                } else {
                    self.infoLabel.text = "Nos has denegado el permiso de grabación de audio. Por favor, activalo en los ajustes de tu dispositivo para continuar."
                }
            }
        }
    }
    
    func askForTranscriptionPermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationCompleted()
                } else {
                    self.infoLabel.text = "Nos has denegado el permiso de transcripción de texto. Por favor, activalo en los ajustes de tu dispositivo para continuar."
                }
            }
        }
    }
    
    func authorizationCompleted() {
        dismiss(animated: true, completion: nil)
    }
}

