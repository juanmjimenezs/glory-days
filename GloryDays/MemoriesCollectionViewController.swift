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

private let reuseIdentifier = "Cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var memories: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadMemories()

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
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths[0]
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
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
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
