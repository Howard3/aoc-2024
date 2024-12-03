package main

import (
	"bytes"
	"fmt"
	"log/slog"
	"os"
	"strconv"
)

type Report struct {
	Values []int
}

func (r Report) IsSafe(damper int) bool {
	incSafely := r.isIncreasingSafely(r.Values, 1, 3, damper)
	decSafely := r.isIncreasingSafely(r.Values, -3, -1, damper) // technically decreasing. lol.

	return incSafely || decSafely
}

func (r Report) ToString() string {
	return fmt.Sprintf("%v", r.Values)
}

func (r Report) newWithRemovedIndex(source []int, index int) []int {
	toReturn := make([]int, len(source))
	copy(toReturn, source)
	return append(toReturn[:index], toReturn[index+1:]...)
}

func (r Report) isIncreasingSafely(input []int, bottomDiff, topDiff, problemDampenerLimit int) bool {
	toTest := input[1:]
	previousValue := input[0]

	for i := 0; i < len(toTest); i++ {
		thisValue := toTest[i]
		didntIncreaseEnough := previousValue+bottomDiff > thisValue
		increasedTooMuch := previousValue+topDiff < thisValue

		if didntIncreaseEnough || increasedTooMuch {
			if problemDampenerLimit > 0 {
				for skipIndex := 0; skipIndex < len(input); skipIndex++ {
					newTest := r.newWithRemovedIndex(input, skipIndex)

					if r.isIncreasingSafely(newTest, bottomDiff, topDiff, problemDampenerLimit-1) {
						slog.Info("damper permitted report", "report", input, "removed", skipIndex)
						return true
					}
				}
			}

			return false
		}

		previousValue = thisValue
	}

	return true
}

type Reports struct {
	Report      []Report
	reportCount int
}

func (r *Reports) AddRawReport(reportLine []byte) error {
	stringValues := bytes.Split(reportLine, []byte(" ")) // split report by spaces

	valueCount := len(stringValues)
	values := make([]int, valueCount)

	for i, v := range stringValues {
		reportValue, err := strconv.Atoi(string(v))
		if err != nil {
			return fmt.Errorf("converting to int: %w", err)
		}

		values[i] = reportValue
	}

	r.Report = append(r.Report, Report{Values: values})
	r.reportCount++

	return nil
}

func (r *Reports) GetSafeReports(damper int) []Report {
	safeReports := make([]Report, 0)

	for _, report := range r.Report {
		if report.IsSafe(damper) {
			safeReports = append(safeReports, report)
		}
	}

	return safeReports
}

func readFileLines(fileName string) (lines [][]byte, err error) {
	data, err := os.ReadFile(fileName)
	if err != nil {
		return nil, fmt.Errorf("reading file: %w", err)
	}

	return bytes.Split(data, []byte("\n")), nil
}

func main() {
	lines, err := readFileLines("./inputs.txt")
	if err != nil {
		panic(err)
	}

	reports := Reports{}
	for _, line := range lines {
		if len(line) == 0 {
			continue
		}

		if err := reports.AddRawReport(line); err != nil {
			panic(fmt.Errorf("adding raw report: %w", err))
		}
	}

	slog.Info("finished reading reports", "count", len(reports.Report))
	safeReports := reports.GetSafeReports(0)
	safeReportsWithDamper := reports.GetSafeReports(1)
	slog.Info("found safe reports", "part1", len(safeReports), "part2", len(safeReportsWithDamper))
}
