const fs = require('fs');
const { jsPDF } = require('jspdf');
fs.mkdirSync('deliverables', { recursive: true });
const doc = new jsPDF({ unit: 'pt', format: 'letter', compress: true });
doc.setProperties({title:'Sleep Audio App — Competitive Analysis',author:'Replit',subject:'Evidence-led competitive analysis and MVP recommendation'});
const W=612,H=792,M=36,C=540;
const colors={ink:'#182736',muted:'#536574',teal:'#086E70',paper:'#FFFFFF',pale:'#EDF5F4',line:'#D9E2E6',navy:'#102A3A'};
let y=0, page=0, commands=[], layouts=[];
function rgb(hex){return [1,3,5].map(i=>parseInt(hex.slice(i,i+2),16));}
function rect(x,y,w,h,color){doc.setFillColor(...rgb(color));doc.rect(x,y,w,h,'F');commands.push({kind:'rect',x,y,w,h,color});}
function text(s,x,yy,size=10.5,color=colors.ink,bold=false,url=null){doc.setFont('helvetica',bold?'bold':'normal');doc.setFontSize(size);doc.setTextColor(...rgb(color));doc.text(s,x,yy);if(url)doc.link(x,yy-size,doc.getTextWidth(s),size+3,{url});commands.push({kind:'text',s,x,y:yy,size,color,bold,url});}
function begin(kicker,title,subtitle){if(page){layouts.push(commands);doc.addPage();}commands=[];page++;rect(0,0,W,8,colors.teal);text('SLEEP AUDIO / COMPETITIVE INTELLIGENCE',M,34,8,colors.muted,true);text('09 OCT 2026',474,34,8,colors.muted);text(kicker.toUpperCase(),M,72,9,colors.teal,true);text(title,M,107,25,colors.navy,true);y=132;if(subtitle)para(subtitle,11,colors.muted);y+=12;}
function ensure(h){if(y+h>735)throw Error(`Page ${page} overflow at ${y}+${h}`);}
function para(s,size=10.5,color=colors.ink,bold=false){doc.setFont('helvetica',bold?'bold':'normal');doc.setFontSize(size);let lines=doc.splitTextToSize(s,C);let lh=size*1.43;ensure(lines.length*lh+9);for(let l of lines){text(l,M,y,size,color,bold);y+=lh;}y+=9;}
function heading(s){ensure(32);y+=7;text(s,M,y,13,colors.teal,true);y+=23;}
function box(label,s){doc.setFont('helvetica','normal');doc.setFontSize(11);const lines=doc.splitTextToSize(s,C-28);const h=42+lines.length*16;ensure(h+16);rect(M,y-12,C,h,colors.pale);text(label,M+14,y+6,10,colors.teal,true);for(let i=0;i<lines.length;i++)text(lines[i],M+14,y+30+i*16,11);y+=h+13;}
function table(headers,rows,widths,size=9){let x=M;let headerY=y;rect(M,y-12,C,30,colors.navy);headers.forEach((h,i)=>{text(h,x+7,y+6,size,'#FFFFFF',true);x+=widths[i];});y+=29;rows.forEach((row,ri)=>{doc.setFontSize(size);doc.setFont('helvetica','normal');let cells=row.map((s,i)=>doc.splitTextToSize(s,widths[i]-14));let h=Math.max(...cells.map(l=>l.length))*size*1.4+17;ensure(h);if(ri%2===0)rect(M,y-10,C,h,colors.pale);let xx=M;cells.forEach((lines,i)=>{lines.forEach((l,j)=>text(l,xx+7,y+3+j*size*1.4,size,i===0?colors.navy:colors.ink,i===0));xx+=widths[i];});y+=h;});y+=14;}
function footer(){let saved=y;rect(M,754,C,1,colors.line);text('RESEARCH SNAPSHOT / PUBLIC SOURCES / NOT CLINICAL ADVICE',M,772,7,colors.muted);text(String(page).padStart(2,'0'),559,772,8,colors.muted,true);y=saved;}

begin('01 / Executive summary','A quieter bedtime, not more content','Concept: a simple sleep-audio app with a curated choice of high-quality sounds.');
box('RECOMMENDATION: VALIDATE A NARROW PRODUCT','Worth testing as a focused, sustainable product. Not yet differentiated enough to justify a broad subscription sleep platform.');
heading('The positioning to test');
para('For adults who want familiar background audio without browsing a wellness library, this is a bedtime sound player that starts their preferred sound in one tap. Unlike broad wellness platforms, it prioritizes immediate playback, stable overnight audio and predictable ownership. This is a proposed positioning, not a validated customer finding.');
heading('Three decisions that matter');
para('1. Compete on bedtime effort, not catalogue size. Rain Rain already offers 50+ free HD sounds, mixing and a fade-out timer. myNoise lists 300+ customizable soundscapes. [1, 7]');
para('2. Treat playback and sound mastering as the product. Seamless transitions, stable loudness, offline availability and lock-screen reliability matter more than decorative screens. Audio quality was not independently auditioned in this research.');
para('3. Test a paid collection before a recurring subscription. myNoise already offers one-time access; some BetterSleep and Rain Rain reviewers object to recurring payment or lost free access. Pricing simplicity is useful, but not unique. [1, 3, 7]');
heading('Scope and confidence');
para('Six main competitors plus built-in and content alternatives. English-language public websites, US App Store listings and a small non-random review sample, checked 9 October 2026. Prices vary by region, platform and offer; US dollars are benchmarks, not an India launch recommendation. No apps were installed, no audio was measured, and no clinical claims were independently assessed.',9.5,colors.muted);
footer();

begin('02 / Competitive landscape','The competitors to take seriously','Publicly visible pricing; listed purchase options may include legacy or promotional offers.');
table(['Competitor','Offer / benchmark','Strength','Strategic constraint'],[
['Rain Rain [1]','50+ free sounds. Annual IAPs: $29.99 and $35.99.','HD endless audio, mixing, softening, favourites and background play.','Closest direct rival. Free tier already exceeds a small new library.'],
['BetterSleep [2, 3]','Website: 7-day trial, then $59.99/year.','Hundreds of mixable options: noise, nature, ASMR and music.','Sampled reviews object to sounds becoming paid. Not a population estimate.'],
['Calm Sleep [4]','Listing states $69.99/year; separate sleep app.','500+ stories, soundscapes, routines, favourites, timers and HealthKit.','Sampled navigation/check-in complaints; other reviews praise the experience.'],
['Headspace [5]','Website: $69.99/year or $12.99/month.','Sleepcasts, music, soundscapes and guided sleep-health content.','Broader guided wellness offer; less focused on a minimal sound player (inference).'],
['Endel [6]','Free edition. IAPs include $119.99/year, lower annual offers and $124.99 lifetime.','Adaptive on-device soundscapes, artist collaborations and offline audio.','Strong personalization rival. Offer-dependent pricing complicates comparison.'],
['myNoise [7, 8]','Free download. Full Access IAP: $19.99, one-time positioning.','300+ soundscapes, human recordings, deep controls, offline and no ads.','Already combines quality and ownership. A simpler flow must be demonstrated, not assumed.']
],[78,140,162,160],9);
para('Company scale: Calm Sleep is a Calm product, not an independent startup. Rain Rain lists Tim Gostony as developer; myNoise describes its founder-led sound engineering. Comparable current revenue, funding stage and headcount were not verified and are not used to rank these products. [1, 4, 8]',9,colors.muted);
footer();

begin('03 / Feature comparison','A small app starts behind','D = documented in the reviewed sources. ND = not established here, not proof of absence. P = proposed.');
table(['Capability','Rain','Better','Calm S.','Headsp.','Endel','myNoise','Yours'],[
['Nature / ambient audio','D','D','D','D','D','D','P'],
['Custom layer mixing','D','D','ND','ND','ND','D','P'],
['Saved favourites / presets','D','D','D','ND','ND','D','P'],
['Timer / fade timer','D','ND','D','ND','D*','ND','P'],
['Offline audio','ND','ND','ND','ND','D','D','P'],
['Guided / narrated sleep','ND','D','D','D','D*','ND','Later'],
['Real-time contextual audio','ND','ND','ND','ND','D','ND','No'],
['One-time access offer','D*','ND','ND','ND','D','D','P'],
['No ads documented','Paid','ND','ND','ND','ND','D','P']
],[148,50,55,57,57,55,60,58],9);
para('Sources: [1-8]. Endel timer documentation refers to timed scenarios / ecosystem tools, not a confirmed identical mobile fade-out timer. Its narrated artist content is not a verified full bedtime-story catalogue. Rain Rain lists packs and tokens, but availability to a new account was not checked.',9,colors.muted);
heading('Honest starting position');
para('The proposed app loses today on content breadth, recognition, mature playback engines and, versus Endel, personalization. None of the planned capabilities can be presented as an existing advantage. The defensible initial ambition is a better experience for a specific group, not more checkmarks.');
heading('Qualitative positioning');
para('Sound-control specialists: Rain Rain and myNoise. Guided / holistic bedtime: Calm Sleep and Headspace. Broad sound library plus guidance: BetterSleep. Adaptive generative audio: Endel. Proposed niche: curated, non-verbal, one-tap bedtime audio. These categories overlap; they are strategic interpretations, not measured rankings.');
footer();

begin('04 / Direct competitors','Rain Rain is the first benchmark','If your product cannot beat the free experience for a particular user, cheaper premium pricing is not enough.');
heading('Head-to-head: Rain Rain');
para('What it already has: 50+ free HD sounds, unlimited playback, mixing, saved combinations, fade-out timer, softening of higher frequencies, background playback and no audio/video ads. A small visual banner is present in the free version. [1]');
para('What your concept currently lacks: a demonstrated playback engine, an established library and a reason to switch from familiar saved mixes. A cleaner screen is only an advantage if task testing shows less effort.');
para('What to test: open app to audible favourite in two actions or fewer, no sign-in before first playback, no bedtime upgrade interruption, and a small curated choice. Compare against Rain Rain on the same device; do not assume these behaviors are absent there.');
heading('Head-to-head: myNoise');
para('myNoise explicitly markets human field recordings and instruments, professional engineering, no ads or subscription, 300+ soundscapes and offline listening. Its listing offers Full Access at $19.99. Sound quality and one-time payment are already occupied positions. [7]');
para("Potential difference: expert-selected presets that require no slider tuning. That appeals only to people who prefer curation over control. Reviews also praise myNoise's newer interface; do not position it as universally difficult. [7]");
heading('The indirect competitor is already on the phone');
para('Apple Background Sounds supports rain, ocean and noise, Control Center access, plus EQ and a stop timer on iOS 26. Basic masking audio with a timer therefore needs no separate purchase. The proposed app must add a valued collection or a materially easier routine. [9]');
para('Other alternatives: existing Spotify/YouTube playlists, a fan, a physical sound machine, or doing nothing. These were identified as substitutes, not audited for current pricing or playback behavior.');
footer();

begin('05 / Review evidence & opportunity','Trust is a useful hypothesis','Small, non-random review sample. Quotes illustrate concerns; they do not establish frequency or current defects.');
box('BETTERSLEEP: LOST ACCESS','A sampled review is titled \"All items require premium\". Developer replies state that BetterSleep is now paid / subscription-based. Preserve access promises and clearly label free versus paid content. [3]');
box('CALM SLEEP: FINDING CONTENT','A sampled review titled \"No full list of content\" objects to categories exposing the same stories and requiring search. Other reviewers call the design simple and relaxing. Test both quick favourites and a complete browseable list. [4]');
box('RAIN RAIN: SUBSCRIPTION VALUE','One reviewer objects to a subscription \"to use the same library of sounds over and over\". Other reviews praise authentic audio and the generous free tier. Test collection ownership without pretending subscriptions never work. [1]');
heading('Where there may be room');
para('A predictable nightly tool: favourites always easy to reach; purchases explained during daytime browsing; no forced account for local use; full track previews; simple restore-purchase flow. This combination is a proposed design direction, not an unserved market proven by the research.');
heading('What is not a gap');
para('Rain sounds, brown noise, mixing, timers, offline playback, high-quality recordings, ad-free use and lifetime access all appear in existing products. No evidence here supports a claim that these features are novel. [1, 2, 6, 7, 9]');
para('Research caution: review text can describe an older version. For example, some myNoise reviews request mixing, while the current description documents Creation Mode. Current documented features take precedence over historical complaints. [7]',9,colors.muted);
footer();

begin('06 / Recommended first version','One screen. Familiar sounds.','Proposed MVP, not a commitment to build or evidence of sleep efficacy.');
heading('Bedtime interface');
para('Home: one large \"Play my usual sound\" control, three favourites, and a small \"Browse sounds\" entry. Player: pause, volume and timer. Browse: Rain / Water / Noise / Night / Soft music. Keep account, purchases and settings outside the bedtime path.');
heading('A curated launch library');
para('Start with 24-36 mastered soundscapes, not hundreds of interchangeable short clips. Examples: soft rain on a window, rain on a tent, gentle ocean, slow stream, distant forest at night, fan, brown noise, pink noise, fireplace and low-motion instrumental ambience. Offer an optional two-layer mix; avoid an advanced mixer at launch.');
heading('Define \"high quality\" in acceptance tests');
para('Clean recordings; no clipping, audible loop clicks or unintended sudden peaks; gradual start and stop; sensible loudness consistency between tracks; long variation before recognizable repetition. Keep lossless masters and compare delivery formats on ordinary phone speakers, headphones and Bluetooth devices.');
para("Use original recordings or licences that explicitly permit in-app distribution, offline storage and looping. Store rights documentation per asset. Do not reuse competitors' clips. This research has not secured a catalogue or verified any licences.");
heading('Playback is the release gate');
para('Test repeated overnight locked-screen playback on actual target devices; downloaded audio with the network off; incoming calls and audio-route changes; timer completion; and battery behavior. Do not promise overnight reliability based on a browser demo alone.');
heading('Leave these out initially');
para('Sleep scores, microphone recording, wearable integration, AI recommendations, celebrity stories, social features and streaks. Treat the product as a relaxation aid, not a treatment for insomnia. Sound preferences differ; do not promise a guaranteed sleep outcome.');
footer();

begin('07 / Commercial recommendation','Sell a collection before a habit tax','Pricing below is an experiment proposal, not observed willingness to pay.');
heading('Pricing model to test');
para('Free: 8-12 excellent sounds, full timer, unrestricted duration and local favourites. Paid: a clearly defined one-time collection unlock. Test $9.99 and $19.99 with real purchase decisions. Premium downloads and a larger curated collection can be included, subject to asset rights and delivery costs.');
para("Important constraint: Rain Rain's free 50+ sounds outperform this proposed free tier in quantity, while myNoise offers broad full access for a listed $19.99. A small paid collection must win on selection and experience, not a nominal discount. [1, 7]");
para('Consider optional subscriptions only after evidence that customers value regularly added recordings, editorial collections or another ongoing service. Avoid an indefinite \"all future content\" promise until support, licence and hosting economics are understood.');
heading('A narrow first audience');
para('Adults who already use non-verbal audio most nights and dislike choosing from large libraries. Recruit users of both free alternatives and paid apps. Do not confuse interest in sleeping better with willingness to pay for another sound player.');
heading('Differentiation that could accumulate');
para('Original, recognizable recordings; trusted mastering; a reliable nightly routine; and distribution to a well-defined audience. Optional local ambience collections, such as monsoon rain, can be tested later. Their demand is unverified and would need a regional competitor scan.');
heading('Low-cost acquisition tests');
para('Show short sound previews and the actual one-tap flow on a focused landing page. Test searches such as \"rain on window for sleep\" rather than a general wellness pitch. Explore small audio creators or travel communities before paying for broad consumer acquisition. These are channel hypotheses, not measured forecasts.');
footer();

begin('08 / Validation & decision','Validate before expanding','Proposed two-week study. Set thresholds before recruiting; report results even when negative.');
table(['Test','Method','Decision evidence'],[
['Does simpler feel better?','12-15 target users perform favourite-play and timer tasks in the prototype and Rain Rain / Apple tools. Counterbalance order.','Observe time, mis-taps and stated preference. Do not rely on compliments or an imagined feature advantage.'],
['Will they use it again?','7-night voluntary diary with playback logging that users consent to.','Count repeat nights, reasons for return and switching back. Self-reported sleep is exploratory, not clinical proof.'],
['Are the sounds good?','Level-matched, blinded comparisons using licensed sample audio; same playback device.','Test comfort, repetition and unpleasant peaks. \"HD\" or high bitrate is not evidence of superior listening.'],
['Will anyone pay?','Show clear $9.99 / $19.99 purchase offers only when usable product and assets are ready.','Real conversions or credible paid-pilot commitments, not stated intent. Small samples are directional.'],
['Does it run all night?','Device-based offline and locked-screen soak tests before inviting paid use.','Document interruptions, timer behavior, route changes and battery usage. Fix blockers before sale.']
],[113,224,203],9.5);
heading('Go / pivot / stop');
para('Go if users prefer the flow, return voluntarily and pay for the collection. Pivot toward a specific audio niche if content is loved but generic simplicity is not a switching reason. Stop expanding if users prefer existing free tools and no paid demand appears.');
heading('Build route after validation');
para('A responsive web prototype can validate browsing and sound preference; it does not prove dependable iPhone overnight playback. Native mobile creation must start on replit.com, not the Replit iOS app. Choose the platform after testing the playback requirements.');
footer();

const sources=[
['1','Rain Rain — US App Store description, reviews and listed purchases','https://apps.apple.com/us/app/rain-rain-sleep-sounds/id478687481'],
['2','BetterSleep — sound library and $59.99 annual website offer','https://www.bettersleep.com/library/sleep-sounds'],
['3','BetterSleep — sampled US App Store reviews and developer replies','https://apps.apple.com/us/app/bettersleep-relax-and-sleep/id314498713?platform=ipad&see-all=reviews'],
['4','Calm Sleep — standalone app description, reviews and annual terms','https://apps.apple.com/us/app/calm-sleep-rest-relax/id6714481749'],
['5','Headspace — sleep content and website subscription terms','https://www.headspace.com/sleep-app?origin=sleep'],
['6','Endel — features, free edition, offline audio and listed purchases','https://apps.apple.com/us/app/endel-focus-sleep-sounds/id1346247457'],
['7','myNoise — soundscape library, ownership model and listed purchases','https://apps.apple.com/us/app/mynoise-relax-sleep-work/id1523675125'],
['8','myNoise — website, donation model and founder context','https://mynoise.net/'],
['9','Apple Support — Background Sounds, EQ and iOS 26 timer','https://support.apple.com/en-us/109346'],
['10','Endel — adaptive soundscapes and ecosystem documentation','https://endel.io/'],
['11','Rain Rain — background playback and fade-out documentation','https://www.rainrainapp.com/']
];
begin('09 / Sources & limitations','Evidence you can open','All sources retrieved 9 October 2026. Click source titles in the PDF.');
for(const [n,label,url] of sources){text(`[${n}] ${label}`,M,y,9.5,colors.teal,true,url);y+=16;doc.setFontSize(8);const lines=doc.splitTextToSize(url,C);for(const l of lines){text(l,M,y,8,colors.muted,false,url);y+=11;}y+=10;}
heading('How to interpret the report');
para('Prices are public offer or App Store purchase listings, not completed checkout quotes. No assumption is made that every listed SKU is offered to every new user. Different currencies, promotions and legacy purchases can coexist. App ratings, download marketing claims and clinical statistics were not used to estimate market size or efficacy.',9.5,colors.muted);
para('Feature availability is established only where reviewed sources describe it. ND cells are unknowns. Review findings are illustrative, not a statistically representative sentiment analysis. Recommendations, launch library size, pricing experiments and the proposed positioning are analyst hypotheses.',9.5,colors.muted);
footer();
layouts.push(commands);
fs.writeFileSync('deliverables/sleep-app-competitive-analysis.pdf',Buffer.from(doc.output('arraybuffer')));
fs.writeFileSync('deliverables/report-layout.json',JSON.stringify(layouts));
console.log(`Created ${doc.getNumberOfPages()} PDF pages.`);
