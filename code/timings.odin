package learn3d

import "core:time"

TimedSectionID :: enum {
	Frame,
	Input,
	Update,
	Render,
	Clear,
	DrawMesh,
	DrawTriangle,
	UI,
	Display,
	Sleep,
	Spin,
}

TimedSection :: struct {
	last_start: time.Tick,
	total_ms:   f64,
	hit_count:  int,
}

Timings :: struct {
	storage:    [len(TimedSectionID) * 2]TimedSection,
	this_frame: []TimedSection,
	last_frame: []TimedSection,
}

GlobalTimings: Timings

init_global_timings :: proc() {
	GlobalTimings.this_frame = GlobalTimings.storage[:len(TimedSectionID)]
	GlobalTimings.last_frame = GlobalTimings.storage[len(TimedSectionID):]
}

begin_timed_frame :: proc() {
	begin_timed_section(.Frame)
}

end_timed_frame :: proc() {
	end_timed_section(.Frame)

	using GlobalTimings
	this_frame, last_frame = last_frame, this_frame
	for timed_section in &this_frame {
		timed_section = TimedSection{time.Tick{0}, 0, 0}
	}
}

begin_timed_section :: proc(id: TimedSectionID) {
	section := &GlobalTimings.this_frame[id]
	section.last_start = time.tick_now()
}

end_timed_section :: proc(id: TimedSectionID, count := 1) {
	section := &GlobalTimings.this_frame[id]
	section.hit_count += count
	section.total_ms += time.duration_milliseconds(time.tick_since(section.last_start))
}
