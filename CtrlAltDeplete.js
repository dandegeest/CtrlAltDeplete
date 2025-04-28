// "Ctrl+Alt+Deplete" @by dldege 
speechda('Control Alt Deplete At_Capacity Planned_Obsolescence Disposable Solid_Waste', 'en-GB', 'm')

let cc = await midin('MiDDi')
//$: note("c a f e").lpf(cc(1).range(0, 1000)).lpq(cc(1).range(0, 10)).sound("sawtooth")
$: s("- <At_Capacity Planned_Obsolescence Solid_Waste Disposable Deplete>").delay(slider(0.472, 0, 2)).pan("<0 0.3 .6 1>")
  .gain(slider(0, 0, 2)).color("blue")
  .stack(s("- <Control Alt Deplete -!3>")
         .delay(slider(0.672, 0, 2))
         .room("<0 .2 .4 .6 .8 1>").color("red")
         .speed(cc(1))).postgain(1.5).spiral()

$: n("0 <-1 <[-2 .. 5] [5 .. -2]>>".add("0,-2").add("<0 -1>/2"))
.scale("f4:minor:pentatonic").dec(.1)
.room(.1).pdec(.02).hpf(200).lpf(500)
.mask("<1@16 0@4>").gain(cc(2))

$: note("<f1(3,8) [- [c2 c3]]>").s("sine").dist(2)
.att("<0 .5>")
.mask("<0@4 1@4 1@16>").gain(slider(0, 0, 5))._spectrum()

samples('github:eddyflux/crate')

$: note("c".add("<0 -7>")).s("rd").dec(1).bank('crate')
.postgain(.3).dist(1).room(.2).late(.125).gain(slider(0, 0, 1))

$: s("<[bd*2 -] rim:1:.6(<1 3>,8)>*2, [- hh]:1*2").dec(.4)
.bank('crate').n(2).dist(.5).speed(.9)
.mask("<0@8 1@16>").gain(slider(0, 0, 1))

$: n("<- - - - [2 1] - - ->*4".add("0,<-2 -3 -4 -3 -2>").add("<0 -1 0 -4>"))
.clip(2).rel(.2).scale("f4:minor").s("sine").clip(1)
.room(.2).delay(.2).postgain(.3).hpf(600).fm(2)
.lpf(sine.range(200,800).slow(11)).gain(slider(0, 0, 1))

$: s("[crackle]").delay(.5)

$: s("<didgeridoo:<0 1 2 3> wind:<0 1 2 3> east:<0 1 2 3 4 5 6 7> crow:<0 1 2 3> gm_guitar_fret_noise:<0 1 2 3 4 5 6> >")
  .slow(2).delay(.75).room(2).color("green")
  .pan("<0 .5 1>").crush("<16 8 7 6 5 4 3 2>")
  .gain(slider(0, 0, 1))

function spag(name){return'https://spag.cc/'+name}
function listToArray(stringList){if(Array.isArray(stringList)){return stringList.map(listToArray).flat()}
return stringList.replaceAll(' ',',').split(',').map((v)=>v.trim()).filter((v)=>v)}
async function spagda(nameList){const names=listToArray(nameList);if(names.length===0){return}
const map={};for(const name of names){map[name]=spag(name)}
samples(map)}
async function speechda(wordList='',locale='en-GB',gender='f'){if(wordList.includes(':')){const[localeArg,wordsArg]=wordList.split(':');if(localeArg.includes('-')){locale=localeArg}else{gender=localeArg}
wordList=wordsArg}
if(locale.includes('/')){const[localeArg,genderArg]=locale.split('/');locale=localeArg;gender=genderArg}
const words=listToArray(wordList);if(words.length===0){return}
samples('shabda/speech/'+locale+'/'+gender+':'+words.join(','))}
async function hubda(orgList,repoList=''){const orgs=listToArray(orgList);const orgRepos=[];const orgChoices=[];for(const org of orgs){if(org.includes('/')){const[orgName,repoName]=org.split('/');orgRepos.push({org:orgName,repo:repoName})}else{orgChoices.push(org)}}
const repoChoices=listToArray(repoList);for(const orgChoice of orgChoices){for(const repoChoice of repoChoices){orgRepos.push({org:orgChoice,repo:repoChoice})}}
const addresses=orgRepos.map(({org,repo})=>'github:'+org+'/'+repo);for(const address of addresses){samples(address)}}
window.speechda=speechda;window.spagda=spagda;window.spag=spag;window.hubda=hubda