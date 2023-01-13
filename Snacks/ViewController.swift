

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