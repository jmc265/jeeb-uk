## Pair programming is difficult (🚧 WIP 🚧)
Pair programming is difficult to practice effectively. Unfortunately, the inverse is also true: **pair programming is easy to practice ineffectively**. It is a learnt skill which is hard to pick up. I have tried to articulate some advice below for both the Driver and Navigator roles:
### General 
- Agree a **destination (goal)** before you start 
	- Everyone needs to be working towards the same outcome
- Agree an **Estimated Time of Arrival (time limit)** before you start
	- Pair Programming is tiring. Make sure to take a break
- There must be **exactly 2 people and 2 roles**: 
	- 2 people and 1 role is wrong
		- 2 drivers grabbing at the wheel will crash the car 
		- 2 navigators will never drive anywhere (possibly this is a design session)
	- 3+ people is wrong
		- This will result in 1 driver and 2+ navigators. The driver will become disorientated trying to listen to 2 or more sets of directions. ["Too many cooks spoil the broth"](https://en.wiktionary.org/wiki/too_many_cooks_spoil_the_broth)
- Both people must be able to **access a keyboard** at all times during the session
	- Sometimes it is easier for the navigator to show their thoughts with actions rather than just words
	- It makes it easier to switch roles (which should be done often)
	- If the session is in person, plug 2 keyboards into the same computer. If done remotely use something like [VSCode Live Share](https://code.visualstudio.com/learn/collaboration/live-share)
- Don't worry about **matching novices with experts**. Certainly that pairing can help with up-skilling but pairs of novices have advantages over solo programming and pairs of experts can solve complex problems.
- Pair programming is **no substitute for code reviews**. Pair programming is a synchronous activity and therefore will suffer from [Groupthink](https://en.wikipedia.org/wiki/Groupthink). Code reviews are an asynchronous activity which gives the reviewer time and space to form their own opinions and thoughts.
- Pair programming is **no substitute for knowledge sharing**. Where applicable, the knowledge should be shared with the whole team, not just 2 people.
### Driver role 🚗 
- **Don't drive too fast** for the navigator. They need to understand where the car currently is located in order to direct properly
- **Listen to directions** from your navigator! If the navigator says it is time to write a unit test, do it. If they say it is time for a refactor, pause and consider that option with them.
### Navigator role 🗺 
- **Think about the bigger picture**. This is the main role of a navigator. How are we going to get to the pre-agreed destination? Do we need to start writing some tests now? Do we need to pause and consider the implications of our change on a different part of the code base? Is it time for a break ☕️?
- **Don't be a back-seat driver**. Pointing out typos is generally unnecessary as the driver likely already knows the problem and the IDE/compiler will probably tell them anyway. Stylistic comments also should be avoided as it breaks the flow of both driver & navigator and this should be solved through dev tooling.

## Links
- [Pair programming is ineffective](https://matt-rickard.com/against-pair-programming/)
- [Pair Programming Antipatterns](https://tuple.app/pair-programming-guide/antipatterns)
- [Tips for "Collaborative programming"](https://vtorosyan.github.io/collaborative-programming/)