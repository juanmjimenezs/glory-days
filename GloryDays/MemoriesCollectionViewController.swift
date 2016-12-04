//
//  MemoriesCollectionViewController.swift
//  GloryDays
//
//  Created by Juan Manuel Jimenez Sanchez on 30/11/16.
//  Copyright © 2016 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit

import AVFoundation
import Photos
import Speech

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate {

    var memories: [URL] = []
    var currentMemory: URL!
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Archivo donde almacenamos temporalmente el audio
        self.recordingURL = getDocumentsDirectory().appendingPathComponent("memory-recording.m4a")
        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    //Las transiciones entre pantallas no es bueno hacerlas en viewDidLoad() porque allí la vista 
    //aún no ha aparecido, lo correcto es hacerlo en esta función
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.checkForGrantedPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkForGrantedPermissions() {
        let photosAuth: Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth: Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth: Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuth && recordingAuth && transcriptionAuth
        
        if !authorized {
            if let termsVc = storyboard?.instantiateViewController(withIdentifier: "showTerms") {
                navigationController?.present(termsVc, animated: true, completion: nil)
            }
        }
    }
    
    /**
     Limpiamos primero el arreglo y luego lo rellenamos con las fotos que encuentre en el directorio.
     */
    func loadMemories() {
        self.memories.removeAll()
        
        //El guard es como un if pero solo con el 'else' y de esta forma segura podemos intentar obtener los archivos del directorio
        guard let files = try? FileManager.default.contentsOfDirectory(at: self.getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return //En caso de encontrar error se sale de la función
        }
        //Si todo ha salido bien con el guard...
        for file in files {
            //Intenta obtener el nombre del archivo pero si no lo consigue no pasa nada
            //guard let fileName = file.lastPathComponent else {continue}
            let fileName = file.lastPathComponent
            
            if fileName.hasSuffix(".thumb") {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                let memoryPath = self.getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        
        self.collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    /**
     Obtenemos la ruta donde guardaremos las imagenes
     */
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths[0]
    }
    
    /**
     Nos permite lanzar la pantalla que permite agregar la imagen.
     */
    func addImagePressed() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    /**
     Aquí obtenemos la imagen seleccionada
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addNewMemory(image: theImage)
            self.loadMemories()
            
            //Con esta linea hacemos que se cierre la pantalla donde selecionamos la imagen
            dismiss(animated: true, completion: nil)
        }
    }
    
    func addNewMemory(image: UIImage) {
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        do {
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomic])
            }
            
            if let thumbnail = resizeImage(image: image, to: 200) {
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: thumbPath, options: [.atomic])
                }
            }
        } catch {
            print("Ha fallado la escritura en disco")
        }
    }
    
    /**
     Aquí se redimensiona la imagen original para obtener el thumb
     */
    func resizeImage(image: UIImage, to width: CGFloat) -> UIImage? {
        let scaleFactor = width / image.size.width
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imageUrl(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbUrl(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioUrl(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionUrl(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 0 {
            return 0//Como es el header entonces tiene cero filas
        } else {
            return self.memories.count
        }
    }

    /**
     Cargamos en cada celda una image, agregamos el gesto de presionar sostenido y le mejoramos un poco el aspecto visual a cada celda
     */
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
    
        // Configure the cell
        let memory = self.memories[indexPath.row]
        let memoryName = self.thumbUrl(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
        
        //Como las celdas son reusadas, entonces validamos que todavía no tenga el reconocimiento de gestos 
        //para no estar asignando estas configuraciones una y otra vez
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed(sender:)))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
        }
    
        return cell
    }
    
    /**
     Esta es la función que se ejecuta cuando presionamos de forma sostenida una celda
     */
    func memoryLongPressed(sender: UILongPressGestureRecognizer) {
        //Cuando inicia el toque sostenido
        if sender.state == .began {
            let cell = sender.view as! MemoryCell//Sabemos que la vista sobre la que se está presionando es una MemoryCell
            
            if let index = collectionView?.indexPath(for: cell) {
                self.currentMemory = self.memories[index.row]//Obtenemos la información de la celda
                //iniciamos grabación
                self.startRecordingMemory()
            }
        }
        //Cuando finaliza el toque sostenido
        if sender.state == .ended {
            self.finishRecordingMemory(success: true)
        }
    }
    
    /**
     Cuando inicia el toque sostenido...
     */
    func startRecordingMemory() {
        self.audioPlayer?.stop()
        
        collectionView?.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let recordingSetings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            self.audioRecorder = try AVAudioRecorder(url: self.recordingURL, settings: recordingSetings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.record()
        } catch let error {
            print(error)
            self.finishRecordingMemory(success: false)
        }
    }
    
    /*
     Cuando finaliza la grabación y finaliza por algún motivo diferente de levantar el dedo de la celda,
     debemos llamar a finishRecordingMemory() para que realice los pasos que se requieren al finalizar.
     */
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            self.finishRecordingMemory(success: false)
        }
    }
    
    /**
     Cuando finaliza el toque sostenido...
     */
    func finishRecordingMemory(success: Bool) {
        collectionView?.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioURL.path) {
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                
                try fileManager.moveItem(at: self.recordingURL, to: memoryAudioURL)
                
                self.transcribeAudioToText(memory: self.currentMemory)
            } catch let error {
                print(error)
            }
        }
    }
    
    /**
     Aquí convertimos el audio en texto
     */
    func transcribeAudioToText(memory: URL) {
        let audio = self.audioUrl(for: memory)
        let transcription = self.transcriptionUrl(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            guard let result = result else {
                print("Ha habido el siguiente error: \(error)")
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Ha habido un error al guardar la transcripción")
                }
            }
        })
    }
    
    /*
     Este metodo es necesario para configurar correctamente el header
     */
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) ->CGSize {
        if section == 0 {
            return CGSize(width: 0, height: 50)
        } else {
            return CGSize.zero
        }
    }
    
    /**
     Cuando hacemos un toque corto sobre la celda...
     */
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = self.memories[indexPath.row]
        let fileManager = FileManager.default
        
        do {
            let audioName = self.audioUrl(for: memory)
            let transcriptionName = self.transcriptionUrl(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path) {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            
            if fileManager.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Error al cargar el audio para reproducir")
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
