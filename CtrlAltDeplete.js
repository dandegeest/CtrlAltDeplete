// "Ctrl+Alt+Deplete" @by dldege 
speechda('Control Alt Deplete At_Capacity Planned_Obsolescence Disposable Solid_Waste', 'en-GB', 'm')

let cc = await midin('MiDDi')

await initHydra({feedStrudel:1, detectAudio:true})
//
osc(13,0,1)
  .modulate(osc(21,0.25,0))
  .modulateScale(osc(34))
  .modulateKaleid(osc(55),0.1,1)
  .out()

// Master stack with all patterns
$: stack(
  // Pattern 1: Speech and control
  s("- <At_Capacity Planned_Obsolescence Solid_Waste Disposable Depleted>")
    .delay(cc(3).range(0,2)).pan("<0 0.3 .6 1>").color("blue")
    .stack(s("- <Control Alt Deplete -!3>")
           .slow(cc(5).range(1,5))
           .delay(cc(2).range(0,1))
           .room("<0 .2 .4 .6 .8 1>").color("red")
           .speed(cc(4).range(-1,2))).spiral(),

  // // Pattern 2: Pentatonic sequence
  // n("0 <-1 <[-2 .. 5] [5 .. -2]>>".add("0,-2").add("<0 -1>/2"))
  //   .scale("f4:minor:pentatonic").dec(.1)
  //   .room(.1).pdec(.02).hpf(200).lpf(500)
  //   .mask("<1@16 0@4>"),

  // Pattern 3: Sine wave pattern
  note("<f1(3,8) [- [c2 c3]]>").s("sine").dist(2)
    .att("<0 .5>")
    .mask("<0@4 1@4 1@16>"),

  s("[numbers:<3 2 1 0>]").slow(5).delay(.5).gain(5),

  // Pattern 8: Sound effects sequence
  s("<didgeridoo:<0 1 2 3> wind:<0 1 2 3> metal:<0 1 2 3> east:<0 1 2 3 4 5 6 7> crow:<0 1 2 3> gm_guitar_fret_noise:<0 1 2 3 4 5 6> marktrees:<0 1 2 3 4 5 6> >")
    .slow(2).delay(.75).room(2).color("green")
    .pan("<0 .5 1>").crush("<16 8 7 6 5 4 3 2>")
).gain(cc(1).range(0,1)) // Master volume control

samples('github:eddyflux/crate')

function spag(name){return'https://spag.cc/'+name}
function listToArray(stringList){if(Array.isArray(stringList)){return stringList.map(listToArray).flat()}
return stringList.replaceAll(' ',',').split(',').map((v)=>v.trim()).filter((v)=>v)}
async function speechda(wordList='',locale='en-GB',gender='f'){if(wordList.includes(':')){const[localeArg,wordsArg]=wordList.split(':');if(localeArg.includes('-')){locale=localeArg}else{gender=localeArg}
wordList=wordsArg}
if(locale.includes('/')){const[localeArg,genderArg]=locale.split('/');locale=localeArg;gender=genderArg}
const words=listToArray(wordList);if(words.length===0){return}
samples('shabda/speech/'+locale+'/'+gender+':'+words.join(','))}
window.speechda=speechda;