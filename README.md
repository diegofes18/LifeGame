# Game of Life in Assembly for Motorola 68K
This project implements the famous Game of Life using Assembly language for the Motorola 68K architecture. The Game of Life is a cellular automaton that was devised by the British mathematician John Horton Conway in 1970. It is a zero-player game, meaning that its evolution is determined by its initial state, requiring no further input. The game consists of a grid of cells, which can be in one of two states, alive or dead. The rules for the evolution of the game are simple:

1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
2. Any live cell with two or three live neighbours lives on to the next generation.
3. Any live cell with more than three live neighbours dies, as if by overpopulation.
4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

## Installation
To use this project, you need to download and install an emulator for the Motorola 68K architecture, such as Easy68K. Once you have the emulator installed, follow these steps:

1. Download the project files to your local machine.
2. Open the emulator with the project on folder *APARTAT*.
3. Save the source file as MAIN3.X68 in the APARTAT3 folder of the project files.
4. Assemble and run the code in the emulator.

## Usage
Once you have the code running in the emulator, the game will start with a randomly generated grid of cells. The game will then evolve according to the rules, and you can watch the patterns that emerge. To exit the game, close the emulator.

## Contributing
If you want to contribute to this project, feel free to fork the repository and submit a pull request. Any contributions are welcome.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
