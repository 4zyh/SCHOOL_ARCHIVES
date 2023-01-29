

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
  
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // 1 Create an instance of HealthySnacks. This is the class from the .mlmodel file’s automatically generated code. You won’t use this class directly, only so you can pass its MLModel object to Vision.
            let healthySnacks = HealthySnacks()
            // 2 Create a VNCoreMLModel object. This is a wrapper object that connects the MLModel instance from the Core ML framework with Vision.
            let visionModel = try VNCoreMLModel(for: healthySnacks.model)
            // 3 Create the VNCoreMLRequest object. This object will perform the actual actions of converting the input image to a CVPixelBuffer, scaling it to 227×227, running the Core ML model, interpreting the results, and so on.
            let request = VNCoreMLRequest(model: visionModel,
                                          completionHandler: {
                                            [weak self] request, error in
                                            print("Request is finished!", request.results ?? "no values")
                                              self?.processObservations(for: request, error: error)
            })
            // 4 The imageCropAndScaleOption tells Vision how it should resize the photo down to the 227×227 pixels that the model expects.
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }()
    
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var cameraButton: UIButton!
  @IBOutlet var photoLibraryButton: UIButton!
  @IBOutlet var resultsView: UIView!
  @IBOutlet var resultsLabel: UILabel!
  @IBOutlet var resultsConstraint: NSLayoutConstraint!

  var firstTime = true

  override func viewDidLoad() {
    super.viewDidLoad()
    cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    resultsView.alpha = 0
    resultsLabel.text = "choose or take a photo"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Show the "choose or take a photo" hint when the app is opened.
    if firstTime {
      showResultsView(delay: 0.5)
      firstTime = false
    }
  }
  
  @IBAction func takePicture() {
    presentPhotoPicker(sourceType: .camera)
  }

  @IBAction func choosePhoto() {
    presentPhotoPicker(sourceType: .photoLibrary)
  }

  func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
    
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    present(picker, animated: true)
    hideResultsView()
  }

  func showResultsView(delay: TimeInterval = 0.1) {
    resultsConstraint.constant = 100
    view.layoutIfNeeded()

    UIView.animate(withDuration: 0.5,
                   delay: delay,
                   usingSpringWithDamping: 0.6,
                   initialSpringVelocity: 0.6,
                   options: .beginFromCurrentState,
                   animations: {
      self.resultsView.alpha = 1
      self.resultsConstraint.constant = -10
      self.view.layoutIfNeeded()
    },
    completion: nil)
  }

  func hideResultsView() {
    UIView.animate(withDuration: 0.3) {
      self.resultsView.alpha = 0
    }
  }

    func classify(image: UIImage) {
        
        // 1 Converts the UIImage to a CIImage object.
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create CIImage")
            return
        }
        // 2 The UIImage has an imageOrientation property that describes which way is up when the image is to be drawn. For example, if the orientation is "down," then the image should be rotated 180 degrees. You need to tell Vision about the image’s orientation so that it can rotate the image if necessary, since Core ML expects images to be upright.
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        // 3 Because it may take Core ML a moment or two to do all the calculations involved in the classification (recall that SqueezeNet does 390 million calculations for a single image), it is best to perform the request on a background queue, so as not to block the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            // 4 Create a new VNImageRequestHandler for this image and its orientation information, then call perform() to actually do execute the request. Note that perform() takes an array of VNRequest objects, so that you can perform multiple Vision requests on the same image if you want to. Here, you just use the VNCoreMLRequest object from the classificationRequest property you made earlier.
            let handler = VNImageRequestHandler(ciImage: ciImage,
                                                orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification: \(error)")
            }
        }