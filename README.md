# MRIQuantSim

MRIQuantSim is an educational and research tool for simulating and visualizing quantitative MRI signal responses to CO₂ breathing challenges. The application provides an interactive environment to generate synthetic MRI and CO₂ time series data with configurable parameters.

## Features

- **Respiratory Simulation**: Model CO₂ waveforms with adjustable breathing rates and variance
- **MRI Signal Simulation**: Generate synthetic BOLD fMRI signals with configurable parameters
- **Noise Modeling**: Add realistic noise, drift (linear, quadratic, cubic), and variance components 
- **Interactive Visualization**: Real-time graphing of signals with adjustable display components
- **Quantitative Analysis**: Calculation of percent signal change metrics and GLM analysis
- **Parameter Customization**: Configurable sampling rates, amplitudes, and experimental design

## Application Structure

The application is organized into several key components:

- **Parameters Tab**: Configure simulation settings for CO₂ and MRI signals
- **Analysis Tab**: View statistical results and quantitative metrics
- **Display Tab**: Customize visualization options for the generated signals

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

## License

See the [LICENSE](LICENSE) file for more information.