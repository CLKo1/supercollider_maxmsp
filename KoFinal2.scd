d = NetAddr.new("127.0.0.1", 7771); // create the NetAddr

(
~b1 = Buffer.read(s,"/Users/chantelleko/Documents/CALGARY/MUSI 661 (SC)/Water, Bubbles, Big, Surfacing 1 SND0525 1.wav");
~b2 = Buffer.read(s,"/Users/chantelleko/Documents/CALGARY/MUSI 661 (SC)/Water, Bubbles, Big, Surfacing 1 SND0525 1.wav");
)

(
SynthDef.new(\bubles, {
	arg amp=1, out=0, buf, rate=1, start, end, mix=1, pan=0;
	var sig, ptr;
	ptr = Phasor.ar(0, BufRateScale.kr(buf) * rate, start, end);
	sig = BufRd.ar(1, buf, ptr);
	sig = sig * amp;
	sig = FreeVerb.ar(sig, mix, 0.8, 0.25);
	sig = PanAz.ar(8, sig, pan); //can pan in 8 chan
	Out.ar(out, sig);
}).add;
)

b = Synth(\bubles, [\start, 0, \end, ~b1.numFrames-1, \rate, 1, \pan, 0]);
b.set(\pan, 1.7); //0/1: 0; 2/3: 0.5; 4/5: 1; 6/7: 1.5; 7/0: 1.7. AKA 0-1.7
b.set(\rate, 0.3); //0.3 - 5
b.set(\mix, 0.1); //0.1 - 1 (dry to wet)
b.set(\amp, 1); //0-1

//Pattern. Plays both chords, and individual notes
(
~lowfc = 200; //alternative method to using Pdefn
~upfc = 5000;
~lowrq = 0.4;
~uprq = 0.7;

Pdefn(\dur, Pwhite(1.0, 3.0, inf)); // Pseq([0.6, 0.15, 0.15], inf).trace); //Pseq([1/4], inf)
Pdefn(\amp, 0.15);
//Pdefn(\fc, 5000);
//Pdefn(\fc, Pwhite(200, 5000, inf));//rand values between these ranges
//Pdefn(\rq, Pwhite(0.4, 0.7, inf));

a = Pbind(
	\instrument, \mySynth,
	\dur, Pdefn(\dur),
	\note, Pxrand([
		/*69,71,73,74,76,78,80,81, //melody notes
		//chords*/

		[23, 35,54,63,64],
		[35, 47,66,75,76],
		[45, 52,54,59,61,64],
		[57, 64,66,71,73,76],
		[28, 40,47,56,59,63],
		[40, 52,59,68,71,75],s
		[42, 52,57,61,63],
		[30,40,45,49,51],
		[57,64,69,73,76],
		[45,52,57,61,64],
		[59,64,68,71,76],
		[47,52,56,59,64],
		[57,62,66,69,74],
		[45,50,54,57,62],
		[56,59,68,71,74],
		[44,47,56,59,62],

	],inf), //makes it infinite
	\amp, Pdefn(\amp), //not sure how to get this to ramp down so it's not an abrupt cutoff
	\fc, Pwhite(Pfunc{~lowfc},Pfunc{~upfc}, inf),
	\rq, Pwhite(Pfunc{~lowrq},Pfunc{~uprq}, inf),
	\out, 0,
).play;
)

~lowfc = 200;
~upfc = 5000;
~lowrq = 0.4;
~uprq = 0.7;

Pdefn(\dur, Pseq([1/4], inf)); //steady at a certain speed
Pdefn(\dur, Pseq([0.6, 0.15, 0.15], inf).trace); //long, short short, long
Pdefn(\dur, Pwhite(1.0, 3.0, inf)); //range of slow longs and shorts

Pdefn(\amp, 0.2); //0.1-0.2 should be good

a.free;

//the GUIs
(
// start server
s.waitForBoot({

var w, startButton, noteControl, cutoffControl, resonControl;
var balanceControl, ampControl;
var node, cmdPeriodFunc;

// define a synth

SynthDef(\mySynth, {
		arg out, note = 36, fc = 1000, rq = 0.25, bal=0, amp=0.4, gate = 1;
        var x;
        x = Mix.fill(4, {
            LFSaw.ar((note + {0.1.rand2}.dup).midicps, 0, 0.02)
        });
        x = RLPF.ar(x, fc, rq).softclip;
        x = RLPF.ar(x, fc, rq, amp).softclip;
        x = Balance2.ar(x[0], x[1], bal);
        x = x * EnvGen.kr(Env.cutoff, gate, doneAction: Done.freeSelf);
        Out.ar(out, x);
    }, [0.1, 0.1, 0.1, 0.1, 0.1, 0]
).add;

// make the window
w = Window("control panel", Rect(20, 600, 440, 310));
w.front; // make window visible and front window.
w.view.decorator = FlowLayout(w.view.bounds);
w.view.decorator.gap=2@2;
w.alwaysOnTop_(true);

// add a button to start and stop the sound.
startButton = Button(w, 75 @ 20);
startButton.states = [
    ["Start", Color.black, Color.green(0.7)],
    ["Stop", Color.white, Color.red(0.7)]
];
startButton.action = {|view|
        if (view.value == 1) {
            // start sound
            node = Synth( "mySynth", [
                "note", noteControl.value,
                "fc", cutoffControl.value,
                "rq", resonControl.value,
                "bal", balanceControl.value,
                "amp", ampControl.value.dbamp ]);
        } {
            // set gate to zero to cause envelope to release
            node.release; node = nil;
        };
		if (view.value == 1)
		{d.sendMsg("/droneStart", 1)}; //sends on/off to Max
		if (view.value == 0)
		{d.sendMsg("/droneStart", 0)};
};

// create controls for all parameters
w.view.decorator.nextLine;
noteControl = EZSlider(w, 430 @ 20, "Note ", ControlSpec(24, 60, \lin, 1, 36, \note),
		//I can't seem to get the slider to send messages to Max with this method... :(
		//{|ez| d.sendMsg("/synthNote", ez.value)},
		//{|ez| (node.set( "note", ez.value )) * (d.sendMsg("/synthNote", ez.value))}, unitWidth:30)
		//{|ez| node.set( "note", ez.value ), d.sendMsg("/synthNote", ez.value)}, unitWidth:30)
		//{|ez| node.set( "note", ez.value )}, {|ez| d.sendMsg("/synthNote", ez.value)}, unitWidth:30)
		{|ez| node.set( "note", ez.value )}, unitWidth:30)
	//if (ez.value > 1) {d.sendMsg("/synthNote", ez.value)}
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);

w.view.decorator.nextLine;
cutoffControl = EZSlider(w, 430 @ 20, "Cutoff ", ControlSpec(200, 5000, \exp,0.01,1000,\Hz),
    {|ez| node.set( "fc", ez.value )}, unitWidth:30)
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);

w.view.decorator.nextLine;
resonControl = EZSlider(w, 430 @ 20, "Reson ", ControlSpec(0.1, 0.7,\lin,0.001,0.2,\rq),
    {|ez| node.set( "rq", ez.value )}, unitWidth:30)
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);

w.view.decorator.nextLine;
balanceControl = EZSlider(w, 430 @ 20, "Balance ", \bipolar,
    {|ez| node.set( "bal", ez.value )},  unitWidth:30)
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);

w.view.decorator.nextLine;
ampControl = EZSlider(w, 430 @ 20, "Amp ", \db,
    {|ez| node.set( "amp", ez.value.dbamp )}, -14, unitWidth:30)
        .setColors(Color.grey,Color.white, Color.grey(0.7),Color.grey, Color.white, Color.yellow);

//------------------------------------------------------------------------------------
~slider = Slider(w, Rect(20,60,150,25))
//.background_(Color(0.2,0.75,0.95))
.action_({
	arg obj;
	var cf;
	cf = obj.value.linexp(0,1,0.3,5).postln;
	if(
		c.isPlaying, //takes the failure messages out if the slider is moving while the button is off
		d.sendMsg("/bufrate", cf);
			{c.set(\rate, cf)}, //how it controls the Synth
	);
	~numberBox.value_(obj.value.linexp(0,1,0.3,5));//slider updates the number box
});

~numberBox = NumberBox(w, Rect(180,60,50,25))
.value_(0.3)
.clipLo_(0.3)
.clipHi_(5)
.decimals_(2)
.action_({
	arg obj;
	~slider.valueAction_(obj.value.explin(0.3,5,0.1)) //the slider updates the number box
});

~freqLabel = StaticText(w, Rect(180,90,80,20))
.string_("rate")
.align_(\center);

//-------------------------------------------
~slider2 = Slider(w, Rect(20,10,150,25))
//.background_(Color(0.2,0.75,0.95))
.action_({
	arg obj;
	var mx;
	mx = obj.value.linexp(0,1,0.1,1).postln;
		if(
		c.isPlaying, //takes the failure messages out if the slider is moving while the button is off
			d.sendMsg("/bufmix", mx);
			{c.set(\mix, mx)} //how it controls the Synth
	);
	~numberBox2.value_(obj.value.linexp(0,1,0.1,1));//slider updates the number box
});

~numberBox2 = NumberBox(w, Rect(180,10,65,25))
.value_(0.3)
.clipLo_(0.3)
.clipHi_(5)
.decimals_(2)
.action_({
	arg obj;
	~slider2.valueAction_(obj.value.explin(0.3,5,0.1)) //the slider updates the number box
});

~mixLabel = StaticText(w, Rect(180,35,50,20))
.string_("mix")
.align_(\center);

//-------------------------------------------
~slider3 = Slider(w, Rect(350,200,165,25))
//.background_(Color(0.2,0.75,0.95))
.action_({
	arg obj;
	var am;
	am = obj.value.linexp(0,1,0.1,1.5).postln;
	if(
		c.isPlaying, //takes the failure messages out if the slider is moving while the button is off
		{c.set(\amp, am)} //how it controls the Synth
	);
	~numberBox3.value_(obj.value.linexp(0,1,0.1,1.5));//slider updates the number box
});

~numberBox3 = NumberBox(w, Rect(180,100,50,25))
.value_(0.1)
.clipLo_(0.1)
.clipHi_(1.5)
.decimals_(2)
.action_({
	arg obj;
	~slider3.valueAction_(obj.value.explin(0.3,5,1.5)) //the slider updates the number box
});

~ampLabel = StaticText(w, Rect(170,130,50,20))
.string_("amp")
.align_(\center);
//-------------------------------------------
~slider4 = Slider(w, Rect(400,250,165,25))
.background_(Color(0.2,0.75,0.95))
.action_({
	arg obj;
	var pos;
	pos = obj.value.linexp(0,1,0.1,10).postln;
	if(
			c.isPlaying, //written like this it looks like the data won't be sent unless the synth is playing. That is not true. The data will always be sent even if the synth is off
			d.sendMsg("/pos", pos);
	);
	~numberBox4.value_(obj.value.linexp(0,1,0.1,10));//slider updates the number box
});

~numberBox4 = NumberBox(w, Rect(180,130,50,25))
.value_(0.1)
.clipLo_(0.1)
.clipHi_(10)
.decimals_(2)
.action_({
	arg obj;
	~slider4.valueAction_(obj.value.explin(0.3,5,0.1)) //the slider updates the number box
});

~posLabel = StaticText(w, Rect(170,130,50,20))
.string_("pos")
.align_(\center);

//-------------------------------------------
~slider5 = Slider(w, Rect(400,280,165,25))
.background_(Color(0.2,0.75,0.95))
.action_({
	arg obj;
	var dim;
	dim = obj.value.linexp(0,1,0.1,10).postln;
	if(
			c.isPlaying, //written like this it looks like the data won't be sent unless the synth is playing. That is not true. The data will always be sent even if the synth is off
			d.sendMsg("/dim", dim);
	);
	~numberBox5.value_(obj.value.linexp(0,1,0.1,10));//slider updates the number box
});

~numberBox5 = NumberBox(w, Rect(180,130,50,25))
.value_(0.1)
.clipLo_(0.1)
.clipHi_(10)
.decimals_(2)
.action_({
	arg obj;
	~slider5.valueAction_(obj.value.explin(0.3,5,0.1)) //the slider updates the number box
});

~dimLabel = StaticText(w, Rect(170,130,50,20))
.string_("dim")
.align_(\center);
//-------------------------------------------
~button = Button(w, Rect(280,20,60,30))
.states_([
	["BUF_OFF", Color.black, Color.gray(0.8)],
	["BUF_ON", Color.white, Color(0.2,0.75,0.95)]
])
.action_({
	arg obj;
	if(
		obj.value == 1,
		{
			c = Synth(
				\bubles,
				[
					\start, 0, \end, ~b1.numFrames-1, \rate, 1, \pan, 0, ~slider.value.linexp(0,1,0.3,5)
					//\rq,
					//~knob.value.linexp(0,1,1,100).reciprocal
				]
		).register},
		{c.free},
			{d.sendMsg("/bufOnOff", obj.value);}
	);
		if(
			obj.value == 1,
			{d.sendMsg("/bufOnOff", 1)}); //sends a 1 to Max
		if(
			obj.value == 0,
			{d.sendMsg("/bufOnOff", 0)});//sends a 0 to Max
});

//----------------------------------------------
	~button2 = Button(w, Rect(20, 50, 80, 30))
	.states_([
		["Pat_PAUSE", Color.black, Color.gray(0.8)],
		["Pat_Play", Color.white, Color(0.2,0.75,0.95)]
])
	.action_({
		arg obj;
		if(obj.value == 1,
			{a.play});
		if(obj.value == 1,
			{d.sendMsg("/patOnOff", 1)});//send on/off to Max
		if(obj.value == 0,
			{a.pause});
		if(obj.value == 0,
			{d.sendMsg("/patOnOff", 0)});
});

	//----------------------------------------------
	~button3 = Button(w, Rect(20, 60, 90, 30))
	.states_([
		["Shape_Off", Color.black, Color.gray(0.8)],
		["Change_Shape", Color.white, Color(0.2,0.75,0.95)]
])
	.action_({
		arg obj;
		if(
		obj.value == 1,
		{
			e = Synth(
				\mySynth,
				[\note, 24, \fc, 200, \rq, 0.4, \amp,
						0.3, \gate, 1]).register});

		if(obj.value == 1,
			{d.sendMsg("/shape", 1)});//send on/off to Max
		if(
		obj.value == 0,
			{e.set(\gate, 0)});

		if(obj.value == 0,
			{d.sendMsg("/shape", 0)});
});

//--------------------------------------------------------------
~button4 = Button(w, Rect(20, 70, 100, 30))
	.states_([
		["Visuals_Off", Color.black, Color.red(0.8)],
		["Visuals_Off", Color.white, Color.red(0.2,0.75,0.95)]
])
	.action_({
		arg obj;
		if(
		obj.value == 1,
		{d.sendMsg("/end", 1)});

		if(obj.value == 0,
			{d.sendMsg("/end", 0)});

});

//---------------------------------------------------
// set start button to zero upon a cmd-period
cmdPeriodFunc = { startButton.value = 0; };
CmdPeriod.add(cmdPeriodFunc);

// stop the sound when window closes and remove cmdPeriodFunc.
w.onClose = {
    node.free; node = nil;
    CmdPeriod.remove(cmdPeriodFunc);
};
});
)





