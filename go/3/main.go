package main

import (
	"bytes"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"strconv"
	"strings"
)

var extractInstructionParts = regexp.MustCompile(`(mul|do|don't)\(([0-9,]*?)\)`)

func main() {
	data, err := os.ReadFile("input.txt")
	if err != nil {
		panic(fmt.Errorf("when reading file %w", err))
	}

	instructions := extractInstructionParts.FindAllSubmatch(data, -1)
	total := 0
	isEnabled := true
	enabledOnlyTotal := 0

	for i := 0; i < len(instructions); i++ {
		isConditionalInstruction := bytes.HasPrefix(instructions[i][0], []byte("do"))
		if !isConditionalInstruction {
			total += runInstruction(instructions[i])
		}

		if isConditionalInstruction {
			isEnabled = conditionalInstructionIsDo(instructions[i])
		} else if isEnabled {
			enabledOnlyTotal += runInstruction(instructions[i])
		}
	}

	slog.Info("found total for part 1", "total", total)
	slog.Info("found total for part 2", "total", enabledOnlyTotal)
}

func conditionalInstructionIsDo(parts [][]byte) (do bool) {
	return string(parts[1]) == "do"
}

func runInstruction(parts [][]byte) int {
	if string(parts[1]) == "mul" {
		return multiply(parts[2])
	}

	panic(fmt.Errorf("unknown instruction %q", parts[0]))
}

func multiply(arguments []byte) int {
	values := strings.Split(string(arguments), ",")
	a, aErr := strconv.Atoi(values[0])
	b, bErr := strconv.Atoi(values[1])

	if err := errors.Join(aErr, bErr); err != nil {
		panic(fmt.Errorf("when multiplying %q got %w", arguments, err))
	}

	return a * b
}
