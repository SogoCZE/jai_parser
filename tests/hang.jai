main :: () {
    log("hello, jails");
}

MyThing :: struct {
}


for_expansion :: (array: *MyThing, body: Code, flags: For_Flags) #expand {
    for i: 0..999 {
        `it := i * 2;
        `it_index := i;

        break it;

        //
        // This is the line, which, when uncommented, will cause the Jails parser to hang.
        //
        #insert(remove=#assert(false), break=break) body;

        #insert body; // Comment this line out and uncomment the #insert above.
    }
}

#import "Basic";