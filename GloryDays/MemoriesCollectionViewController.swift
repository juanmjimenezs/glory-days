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

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var memories: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

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

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
    
        // Configure the cell
        let memory = self.memories[indexPath.row]
        let memoryName = self.thumbUrl(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
    
        return cell
    }
    
    /**
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
