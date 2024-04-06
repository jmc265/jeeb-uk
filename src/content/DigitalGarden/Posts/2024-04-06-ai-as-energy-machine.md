---
title:  "Does AI conform to the laws of thermodynamics?" 
permalink: ai-as-energy-machine/
layout: post
tags: 
  - posts
  - programming
  - ai
  - machine learning
  - perpetual motion
---

I have started down a thought experiment, comparing "AI" systems to physical engines like the internal combustion engine, fusion/fission reactors, and eventually to perpetual motion machines.

The analogy starts by understanding that internal combustion engines (and reactors) take a large amount of energy to start up. The comparison with AI is the vast quantity of manually annotated/captioned training data that goes into generating an AI model in the first place (I am sure there is an apt image here of the old-timey hand-crank starters and large amount of physical energy needed to start cars).

The initial input for the system (fuel in the case of the engine, structured data in the case of a model) allows the thing to "ignite" and "tick over". But in order to become useful, the engine needs to be fed with additional fuel so that it can rev higher and in the end move the car. The same is true for AI systems. They will only continue in their "tick over" state (defined by the quantity/quality of input data) until they are fed with more data in order to become better versions of themselves. 

The trouble for the model creators though is access to this vast amount of quality training data. If humans don't continue to generate and feed this data to the model, the model can only tick over in the same state that it has always been in.

To further the analogy a bit; if you put bad quality (or the wrong sort of) fuel into an engine, the output will start to degrade. The car will have trouble continuing along the road, and may even stop altogether. Again, comparing with AI models, this means that if you input poor quality data in, the model itself will not operate correctly. This is an age-old problem of "Garbage-In, Garbage-Out" (GIGO) that has long been identified in Computer Science in many different areas. I would also add, that using the output of one model as the input for another does not follow here either. You are looking at photocopies of photocopies... Something is always lost in the transfer here and the input wears down until it is useless for the model.

The last thought I had was along the lines of the fabled "perpetual motion machines" which, once given the initial input of energy to ignite, continue infinitely without further input of energy. This is does not work as energy is never transferred with 100% efficiency and the machine will inevitably slow to a stop. If the analogy holds here, then AI systems will have a hard time continuing to be useful without more and more input to sustain them.
