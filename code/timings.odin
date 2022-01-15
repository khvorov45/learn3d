package learn3d

import "core:time"

TimedSectionStorage: [100]TimedSection

ThisFrameTimedSectionStorage := TimedSectionStorage[:50]
LastFrameTimedSectionStorage := TimedSectionStorage[50:]

ThisFrameTimedSectionCount := 0
LastFrameTimedSectionCount := 0

CurrentTimedSection: ^TimedSection

TimedSection :: struct {
	id:                          string,
	start:                       time.Tick,
	end:                         Maybe(time.Tick),
	parent, next_sibling, child: ^TimedSection,
}

begin_timed_frame :: proc() {
	begin_timed_section("Frame")
}

end_timed_frame :: proc() {
	end_timed_section()

	ThisFrameTimedSectionStorage, LastFrameTimedSectionStorage = LastFrameTimedSectionStorage,
	ThisFrameTimedSectionStorage

	LastFrameTimedSectionCount = ThisFrameTimedSectionCount
	ThisFrameTimedSectionCount = 0

	CurrentTimedSection = nil
}

begin_timed_section :: proc(id: string) {

	assert(ThisFrameTimedSectionCount < len(ThisFrameTimedSectionStorage))

	section := &ThisFrameTimedSectionStorage[ThisFrameTimedSectionCount]
	ThisFrameTimedSectionCount += 1

	section^ = TimedSection{id, time.tick_now(), nil, nil, nil, nil}

	if CurrentTimedSection != nil {
		if CurrentTimedSection.end == nil {
			section.parent = CurrentTimedSection
			CurrentTimedSection.child = section
		} else {
			CurrentTimedSection.next_sibling = section
			section.parent = CurrentTimedSection.parent
		}
	}

	CurrentTimedSection = section
}

end_timed_section :: proc() {

	assert(CurrentTimedSection != nil)
	if CurrentTimedSection.end != nil {
		CurrentTimedSection = CurrentTimedSection.parent
		assert(CurrentTimedSection != nil)
	}
	CurrentTimedSection.end = time.tick_now()

}
