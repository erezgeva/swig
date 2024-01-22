package main

import dm "swigtests/director_min"

type MinCallback struct{}

func (p *MinCallback) Run() bool {
  return true
}

func main() {
    callback := dm.NewDirectorCallback(&MinCallback{})
    caller := dm.NewCaller(callback)
    if !caller.Call() {
      panic("Should return true")
    }
}
