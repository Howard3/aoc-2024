package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"os"
	"regexp"
	"sort"
	"strconv"
)

var lineMatcher = regexp.MustCompile(`^(?P<left>[0-9]+)\s+(?P<right>[0-9]+)$`)

type compareLists struct {
	left  []int
	right []int
	num   int
}

func (cl *compareLists) Add(left, right int) {
	cl.left = append(cl.left, left)
	cl.right = append(cl.right, right)
	cl.num++
}

func (cl *compareLists) sort() {
	sort.Ints(cl.left)
	sort.Ints(cl.right)
}

func (cl *compareLists) CalculateLeftRightDistance() int {
	cl.sort()

	distance := 0

	for i := 0; i < cl.num; i++ {
		left := cl.left[i]
		right := cl.right[i]
		diff := int(math.Abs(float64(left - right)))
		distance += diff

		slog.Info("Calculating diff", "left", left, "right", right, "diff", diff, "running_diff", distance)
	}

	return distance
}

func (cl *compareLists) CalculateSimilarityScore() int {
	cl.sort()

	simScore := 0
	for i := 0; i < cl.num; i++ {
		left := cl.left[i]
		rightCount := cl.countInRightList(left)
		thisScore := left * rightCount
		simScore += thisScore

		slog.Info("Calculating similarity score", "left", left, "rightCount", rightCount, "thisScore", thisScore, "running_score", simScore)
	}

	return simScore
}

func (cl *compareLists) countInRightList(v int) int {
	count := 0
	for i := 0; i < cl.num; i++ {
		if cl.right[i] == v {
			count++
		}
	}

	return count
}

func main() {
	file, err := os.Open("./lists.txt")
	if err != nil {
		panic(fmt.Errorf("failed to open file %w", err))
	}
	defer file.Close()

	lists := compareLists{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := bytes.TrimSpace(scanner.Bytes())
		if len(line) == 0 {
			continue
		}
		l, r, err := parseLine(line)
		if err != nil {
			panic(fmt.Errorf("failed to process line %w", err))
		}
		lists.Add(l, r)
	}

	if err := scanner.Err(); err != nil {
		panic(fmt.Errorf("failed scanning file %w", err))
	}

	diff := lists.CalculateLeftRightDistance()
	simScore := lists.CalculateSimilarityScore()

	slog.Info("Found diff", "diff", diff)
	slog.Info("Found Similary Score", "score", simScore)

}

func parseLine(line []byte) (left, right int, err error) {
	matches := lineMatcher.FindSubmatch(line)
	if len(matches) != 3 { // allow 3, #0 is everything.
		return 0, 0, fmt.Errorf("incorrect number of matches found, found %d matches: %s in line %s", len(matches), matches, line)
	}

	l, lerr := strconv.ParseInt(string(matches[1]), 10, 64)
	r, rerr := strconv.ParseInt(string(matches[2]), 10, 64)

	if err := errors.Join(lerr, rerr); err != nil {
		return 0, 0, err
	}

	return int(l), int(r), nil
}
