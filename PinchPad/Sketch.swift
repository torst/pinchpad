//
//  Sketch.swift
//  
//
//  Created by Ryan Laughlin on 4/24/15.
//
//

import UIKit
import CoreData
import ImageIO
import MobileCoreServices

class Sketch: NSManagedObject {
    @NSManaged var caption: String
    @NSManaged var createdAt: NSDate
    @NSManaged var duration: Double
    @NSManaged var imageData: NSData
    @NSManaged var rawService: Int16
    @NSManaged var syncError: Bool
    @NSManaged var syncStarted: NSDate?
    
    class var managedContext: NSManagedObjectContext {
        get {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            return appDelegate.managedObjectContext!
        }
    }
    
    
    // MARK: Animation
    
    class var animationFrames: [Sketch]{
        get {
            let fetchRequest = NSFetchRequest(entityName: "Sketch")
            fetchRequest.predicate = NSPredicate(format: "duration != 0")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            if let fetchResults = (try? Sketch.managedContext.executeFetchRequest(fetchRequest)) as? [Sketch] {
                return fetchResults
            } else {
                return []
            }
        }
    }
    
    class var animationFrameCount: Int{
        get {
            return self.animationFrames.count
        }
    }

    class func assembleAnimatedGif() -> NSData?{
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        
        let documentsDirectory = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: documentsDirectory).URLByAppendingPathComponent("animated.gif")

        let frames = Sketch.animationFrames
        let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frames.count, nil)
        CGImageDestinationSetProperties(destination!, fileProperties)
        
        for frame in frames {
            let actualImage = UIImage(data: frame.imageData)
            let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: frame.duration]]
            CGImageDestinationAddImage(destination!, actualImage!.CGImage!, frameProperties)
        }
        
        if CGImageDestinationFinalize(destination!) {
            // TODO: delete animation frames from CoreData
            return NSData(contentsOfURL: url)
        } else {
            return nil
        }
    }
    
    class func clearAnimationFrames(){
        for frame in self.animationFrames{
            Sketch.managedContext.deleteObject(frame)
        }
        try! Sketch.managedContext.save()
    }
    
    func imageType() -> String{
        var array = [UInt8](count: 1, repeatedValue: 0)
        self.imageData.getBytes(&array, length: 1)
        
        if (array[0] == 0x47){
            return "image/gif"
        } else {
            return "image/png"
        }
    }
}
