# Lesson: BUG-003 — `\crossStaff { }` braces treated as parallel separators

## Symptom
Gnossienne accompaniment figures wrapped in `\crossStaff { … }` splintered into
phantom simultaneous voices, corrupting the voice structure that followed.

## Root cause
The prototype treated every brace after certain commands like the walls of a
`<< … >>` group. But brace semantics are context-dependent: `\crossStaff` is an
engraving hint, and its braces group exactly like bare `{ }`.

## The guard now in place
`BUG003_CrossStaffBracesSplitVoices`: the parse tree keeps a crossStaff group's
events sequential, and a recursive assertion proves no parallel node appears
under one.

## Lesson
Grammar over pattern-matching. A recursive-descent parser gives each construct
its own rule, so context-dependent syntax cannot be mistaken for its lookalike.
