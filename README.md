# MRIQuantSim

MRIQuantSim is an educational and research tool for simulating and visualizing quantitative MRI signal responses to CO₂ breathing challenges. The application provides an interactive environment to generate synthetic MRI and CO₂ time series data with configurable parameters.

## Features

- **Respiratory Simulation**: Model CO₂ waveforms with adjustable breathing rates and variance
- **MRI Signal Simulation**: Generate synthetic BOLD fMRI signals with configurable parameters
- **Flexible Response Shapes**: Choose between boxcar or exponential response functions with customizable time constants
- **Noise Modeling**: Add realistic noise, drift (linear, quadratic, cubic), and variance components 
- **Interactive Visualization**: Real-time graphing of signals with adjustable display components
- **Customizable Analysis Models**: Analyze data with different model specifications than those used for simulation
- **Model Mis-specification Testing**: Compare analysis results when the model matches or differs from the signal shape
- **Quantitative Analysis**: Calculation of percent signal change metrics and GLM analysis
- **Parameter Customization**: Configurable sampling rates, amplitudes, and experimental design

## Application Structure

The application is organized into several key components:

- **Signal Tab**: Configure all simulation settings
  - *Signal Parameters*: Basic settings for sampling rates and amplitudes
  - *Response Parameters*: Define response shapes (boxcar or exponential with time constants)
  - *Noise Parameters*: Configure variance and noise components
  - *Drift Parameters*: Set drift components for signal trends
  
- **Analysis Tab**: Configure analysis models and view results
  - *Analysis Model Specification*: Define the model shape independently from the simulation
  - *Detrending Model Components*: Select which terms to include in the GLM analysis
  - *Model Results*: View statistical results and percent change metrics
  
- **Display Tab**: Customize visualization options
  - *Waveform Display*: Toggle visibility of different signal components
  - *Scaling Options*: Control y-axis scaling for optimal visualization

## Requirements

- macOS (developed with Xcode for Apple platforms)
- Swift 6.0

## Build and Run

You can build and run the application using Xcode:

1. Open `MRIQuantSim.xcodeproj` in Xcode
2. Build with `⌘B` or run with `⌘R`

Alternatively, use the command line:
```
xcodebuild -project MRIQuantSim.xcodeproj -scheme MRIQuantSim build
xcodebuild -project MRIQuantSim.xcodeproj -scheme MRIQuantSim run
```

## Testing

Run tests using Xcode's test navigator (`⌘U`) or via command line:
```
xcodebuild test -project MRIQuantSim.xcodeproj -scheme MRIQuantSim
```

## Recent Enhancements

### Response Shape Modeling

The application now supports multiple response shape types:

- **Boxcar**: Traditional step function response model used in block-design fMRI
- **Exponential**: Physiologically realistic model with customizable time constants
  - *Rise Time Constant*: Controls the speed of response onset 
  - *Fall Time Constant*: Controls the speed of response decay

### Independent Analysis Models

A key enhancement is the ability to use different models for simulation and analysis:

- Simulate data with one response shape (e.g., exponential)
- Analyze it with a different model (e.g., boxcar)
- Observe the impact of model mis-specification on analysis results
- Easily sync analysis parameters with simulation when desired

This feature provides valuable insights into how model selection affects quantitative measurements in real-world data, making it an excellent educational tool for understanding the complexities of fMRI analysis.

## License

See the [LICENSE](LICENSE) file for more information.
