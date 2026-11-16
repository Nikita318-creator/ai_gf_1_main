import Foundation

struct QuizQuestionModel {
    let questionText: String
    let options: [String]
    let correctIndex: Int
}

final class QuizViewModel {
    let topic: QuizTopic
    private(set) var questions: [QuizQuestionModel] = []
    private(set) var score: Int = 0
    private(set) var currentQuestionIndex: Int = 0
    
    init(topic: QuizTopic) {
        self.topic = topic
        loadQuestions()
    }
    
    var totalQuestions: Int {
        return questions.count
    }
    
    var currentQuestion: QuizQuestionModel? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    private func loadQuestions() {
        // Боевой массив вопросов для первого топика (Fashion Designer)
        if topic.title == "Fashion Designer" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is a 'toile' in fashion design?",
                    options: [
                        "A test garment made from inexpensive fabric to check fit",
                        "A specialized tool for measuring sleeve length",
                        "A type of high-gloss leather finish",
                        "A digital pattern-making software"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'haute couture' literally translate to from French?",
                    options: [
                        "Modern tailoring",
                        "High sewing / high dressmaking",
                        "Luxury street style",
                        "Exclusive handmade shoes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the primary purpose of a fashion mood board?",
                    options: [
                        "To track production costs and inventory",
                        "To visualize design concepts, colors, and inspiration",
                        "To measure body proportions for tailoring",
                        "To display final pricing tags for retail"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does a 'bias cut' mean in garment construction?",
                    options: [
                        "Cutting fabric at a 45-degree angle to the grain for drape",
                        "Trimming raw edges with a zigzag stitch",
                        "Stitching dual layers for extra warmth",
                        "Using asymmetrical hems for dramatic effect"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is 'grading' in apparel manufacturing?",
                    options: [
                        "Rating fabric quality from A to Z",
                        "Scaling a master pattern into various sizes",
                        "Inspecting stitching defects on the assembly line",
                        "Categorizing designer collections by season"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which iconic designer popularized the 'Little Black Dress' in the 1920s?",
                    options: ["Christian Dior", "Giorgio Armani", "Coco Chanel", "Yves Saint Laurent"],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is a 'lookbook' used for in the fashion industry?",
                    options: [
                        "A portfolio of makeup looks for runway models",
                        "A promotional collection of photos showcasing outfits to buyers",
                        "A textbook on historical costume design",
                        "A catalog of sewing machine manuals"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which natural fiber comes from the cocoons of silkworm larvae?",
                    options: ["Linen", "Silk", "Cashmere", "Hemp"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the function of a basting stitch?",
                    options: [
                        "Permanent heavy-duty reinforcement along seams",
                        "Temporary stitching to hold pieces together before final sewing",
                        "Decorative embroidery on denim cuffs",
                        "Securing buttons and heavy zippers"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'fast fashion' primarily characterized by?",
                    options: [
                        "Handmade bespoke garments crafted over months",
                        "Rapid translation of runway trends into mass-market retail",
                        "Using exclusively organic, biodegradable textiles",
                        "High-priced luxury collections released weekly"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Tattoo Artist" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is the primary purpose of a needle grouping like 'RL' (Round Liner)?",
                    options: [
                        "Creating sharp outlines and clean line work",
                        "Filling large solid color blocks quickly",
                        "Performing smooth whip shading and gradients",
                        "Executing soft greywash portraits"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'blowout' mean in tattooing?",
                    options: [
                        "The tattoo machine overheating due to high voltage",
                        "Ink spreading into deeper tissue layers, causing blurred, hazy lines",
                        "A sudden power surge breaking the needle cartridge",
                        "The client fainting during a long session"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What medical device is standard for sterilizing reusable metal grips and tubes?",
                    options: ["UV-C Light Box", "Chemical Bleach Soak", "Autoclave", "Ultrasonic Heater"],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is the function of stenciling transfer fluid (or soap) on skin?",
                    options: [
                        "To numb the pain temporarily",
                        "To disinfect the epidermis before shaving",
                        "To react with thermal stencil paper and transfer the design clearly",
                        "To lock in pigments instantly without a needle"
                    ],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "Which art style is characterized by heavy solid black ink coverage, high contrast, and bold geometric or tribal patterns?",
                    options: ["Blackwork", "Realism", "Watercolor", "Neo-Traditional"],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is the purpose of a 'second skin' breathable bandage applied right after a tattoo?",
                    options: [
                        "To keep the ink wet permanently",
                        "To protect the fresh wound from bacteria while allowing it to breathe and heal",
                        "To eliminate the need for any future touch-ups",
                        "To speed up chemical ink removal"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'greywash' shading created with?",
                    options: [
                        "Diluted black tattoo ink mixed with distilled water or shading solution",
                        "Specialized metallic grey pigments",
                        "A mixture of white ink and carbon dust",
                        "Burned charcoal extract"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "Why do tattoo artists use Green Soap during the tattooing process?",
                    options: [
                        "To permanently seal the skin pores",
                        "To clean excess ink, lubricate the skin, and maintain hygiene",
                        "To numb nerve endings on sensitive areas",
                        "To make the stencil stick even better mid-session"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'freehand' or 'dermographic' tattooing?",
                    options: [
                        "Tattooing without using a power supply or machine",
                        "Drawing the design directly onto the client's skin with markers instead of a stencil",
                        "Using both hands simultaneously with two machines",
                        "Tattooing blindfolded for practice"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a rotary tattoo machine primarily driven by?",
                    options: [
                        "An electromagnetic coil armature bar system",
                        "A direct motor with an eccentric cam wheel converting rotational motion to linear motion",
                        "Pneumatic air pressure compressor tubes",
                        "Hydraulic fluid pistons"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Indie Musician" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is the main function of a DAW (Digital Audio Workstation)?",
                    options: [
                        "To stream music live to global radio stations",
                        "To record, edit, mix, and produce audio tracks",
                        "To manage copyright registration automatically",
                        "To design album covers and merchandise"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is an ISRC code used for in the music industry?",
                    options: [
                        "Tracking unique sound recordings and music videos for royalties and distribution",
                        "Securing a band name trademark internationally",
                        "Encrypting audio files against piracy",
                        "Measuring live concert ticket sales"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is the purpose of audio 'mastering'?",
                    options: [
                        "Recording individual vocal tracks in a booth",
                        "Writing the sheet music arrangement for instruments",
                        "The final stage of audio post-production, optimizing loudness, balance, and commercial readiness",
                        "Creating raw demo sketches with acoustic guitar"
                    ],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is a 'stem' in music mixing?",
                    options: [
                        "A solo vocal take without effects",
                        "A sub-mix audio file of grouped tracks, such as all drum elements or all synths",
                        "The intro section of an indie song",
                        "A microphone cable connector standard"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'sidechain compression' typically used for in electronic or modern indie production?",
                    options: [
                        "To make vocals sound wider in stereo",
                        "To duck the volume of bass/synths slightly whenever the kick drum hits for clarity",
                        "To boost high frequencies on acoustic guitars",
                        "To remove background noise from guitar amps"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What platform is widely known among independent artists for direct-to-fan music sales and merch?",
                    options: ["Bandcamp", "Billboard Chart", "SoundCloud Pro", "Ticketmaster"],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is an EPK (Electronic Press Kit) used for?",
                    options: [
                        "Packing physical vinyl records securely for shipping",
                        "A professional digital portfolio sent to promoters, blogs, and booking agents",
                        "An emergency repair kit for guitar pedals",
                        "A software plugin bundle for mixing"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What do performance rights organizations like ASCAP, BMI, or PRS collect?",
                    options: [
                        "Physical merchandise production fees",
                        "Public performance royalties when music is played live, broadcast, or streamed publicly",
                        "Social media verification fees",
                        "Studio rental taxes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is acoustic room treatment (like bass traps and acoustic panels) designed to do?",
                    options: [
                        "Make the room completely soundproof to the outside world",
                        "Absorb unwanted reflections and standing waves for accurate monitoring",
                        "Increase the natural reverb of vocals",
                        "Protect equipment from electrical surges"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is distribution aggregators' role (like DistroKid or TuneCore) for indie musicians?",
                    options: [
                        "Booking live concert tours worldwide",
                        "Delivering music files and metadata to streaming platforms like Spotify and Apple Music",
                        "Mixing and mastering tracks professionally",
                        "Designing official merchandise"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Python Developer" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is the key difference between a Python list and a tuple?",
                    options: [
                        "Lists are immutable, tuples are mutable",
                        "Lists are mutable, tuples are immutable",
                        "Tuples can only contain integers",
                        "Lists can only store strings"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does PEP 8 stand for in the Python community?",
                    options: [
                        "Python Enhancement Proposal 8 - Official Style Guide for Python Code",
                        "Python Execution Protocol version 8",
                        "Performance Evaluation Parameter 8",
                        "Private Extension Package standard"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is a decorator in Python?",
                    options: [
                        "A tool to style the terminal output of a script",
                        "A design pattern used exclusively for GUI creation",
                        "A function that takes another function and extends its behavior without modifying it explicitly",
                        "An automated code formatter like Black"
                    ],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is the primary purpose of the `__init__` method in a class?",
                    options: [
                        "To delete an object from memory (destructor)",
                        "To initialize attributes of a newly created object (constructor)",
                        "To convert an object into a JSON string",
                        "To compare two object instances"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a generator in Python and why use it?",
                    options: [
                        "A function that uses `yield` to return items one by one, saving memory for large datasets",
                        "A script that auto-generates unit tests",
                        "A module for building randomized passwords",
                        "A compiler optimization tool for CPython"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does the GIL (Global Interpreter Lock) in CPython restrict?",
                    options: [
                        "Network socket connections",
                        "Multiple native threads from executing Python bytecodes at once",
                        "Memory allocation size to 4GB",
                        "Importing external C libraries"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which built-in Python module is used for regular expression matching operations?",
                    options: ["regex", "match", "re", "pattern"],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is the difference between `is` and `==` operators in Python?",
                    options: [
                        "`is` checks object identity in memory, `==` checks value equality",
                        "`is` checks value equality, `==` checks memory addresses",
                        "There is no difference, they are interchangeable aliases",
                        "`is` is used for numbers, `==` is used for strings"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is list comprehension in Python?",
                    options: [
                        "A method to summarize a list into a single integer",
                        "A concise, readable way to create new lists based on existing iterables",
                        "A built-in AI tool to parse natural language lists",
                        "An error-handling block for indexing exceptions"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a virtual environment (`venv`) used for?",
                    options: [
                        "Running Python inside a web browser via WebAssembly",
                        "Isolating project dependencies and package versions from the global system environment",
                        "Simulating multiple CPU cores for parallel computing",
                        "Testing code security in a sandbox"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Pastry Chef" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is the technique of 'laminating' dough used for?",
                    options: [
                        "Coating cakes in edible sugar sheets",
                        "Folding butter into dough repeatedly to create thin, flaky layers (like croissants)",
                        "Sealing pie crust edges with egg wash",
                        "Pressing cookie dough flat before baking"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the main chemical difference between baking soda and baking powder?",
                    options: [
                        "Baking soda requires an acid ingredient to activate; baking powder already contains an acid component",
                        "Baking powder is liquid, baking soda is solid crystal",
                        "Baking soda is used for bread, baking powder for chocolate only",
                        "There is no difference; they are brand names for the same compound"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is the purpose of tempering chocolate?",
                    options: [
                        "To melt it quickly in a microwave without burning",
                        "To stabilize cocoa butter crystals, resulting in a glossy shine, crisp snap, and no bloom",
                        "To add artificial fruit flavors and coloring",
                        "To lower the melting point below room temperature"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are the primary ingredients of a classic ganache?",
                    options: [
                        "Egg whites and granulated sugar",
                        "Flour, butter, and water",
                        "Chocolate and warm heavy cream",
                        "Cream cheese and powdered sugar"
                    ],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is choux pastry uniquely known for during its preparation?",
                    options: [
                        "Being fried in oil like doughnuts",
                        "Being cooked on a stove in a pan first before baking, creating a hollow center for filling",
                        "Requiring 24 hours of cold fermentation",
                        "Never using eggs or dairy"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'blind baking' a pie crust?",
                    options: [
                        "Baking without turning on the oven light",
                        "Baking a pastry crust partially or fully without filling, typically using pie weights",
                        "Using pre-made frozen dough from a supermarket",
                        "Mixing ingredients without looking at a recipe"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is pectin used for in baking and pastry arts?",
                    options: [
                        "A natural gelling agent derived from fruits, used in jams, jellies, and fruit glazes",
                        "A leavening agent for heavy sourdough breads",
                        "A food coloring extracted from plants",
                        "A stabilizer for whipped cream"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is crème pâtissière (pastry cream)?",
                    options: [
                        "A whipped heavy cream topping for cakes",
                        "A rich, starch-thickened custard used to fill éclairs, tarts, and cream puffs",
                        "A butter-based frosting flavored with vanilla extract",
                        "A liquid syrup used to soak sponge cakes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What causes a meringue to fail or lose its volume during whipping?",
                    options: [
                        "Presence of even a small trace of fat or oil in the bowl",
                        "Using room-temperature egg whites",
                        "Adding sugar too slowly",
                        "Using copper bowls"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is 'fondant' primarily made of?",
                    options: [
                        "Ground almonds and egg yolks",
                        "Sugar, water, corn syrup, and sometimes gelatin or glycerin",
                        "Melted white chocolate and butter",
                        "Marshmallow cream and cocoa powder"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Fitness Coach" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is 'progressive overload' in strength training?",
                    options: [
                        "Gradually increasing weight, frequency, or reps over time to continuously stimulate muscle adaptation and growth",
                        "Lifting to absolute muscular failure on every single set",
                        "Overworking the same muscle group every day without rest",
                        "Stretching beyond comfortable range of motion"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is the fundamental difference between aerobic and anaerobic exercise?",
                    options: [
                        "Aerobic uses oxygen for sustained energy; anaerobic relies on energy sources without oxygen for short, explosive bursts",
                        "Aerobic is done outdoors; anaerobic is done in a gym",
                        "Aerobic burns protein; anaerobic burns carbohydrates exclusively",
                        "There is no difference in metabolic pathways"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is the RPE (Rate of Perceived Exertion) scale typically used for?",
                    options: [
                        "Measuring daily calorie expenditure via smartwatches",
                        "Quantifying subjective exercise intensity on a scale from 1 to 10",
                        "Calculating maximum heart rate formulas",
                        "Evaluating flexibility levels"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'hypertrophy' mean?",
                    options: [
                        "Loss of muscle mass due to inactivity",
                        "An increase in the size of muscle cells and tissue",
                        "Rapid dehydration during intense cardio",
                        "Inflammation of joints from overtraining"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are the three primary macronutrients essential for human nutrition?",
                    options: [
                        "Vitamins, Minerals, Water",
                        "Proteins, Carbohydrates, Fats",
                        "Fiber, Antioxidants, Caffeine",
                        "Amino acids, Electrolytes, Glucose"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is dynamic stretching best utilized for?",
                    options: [
                        "Cooling down and lengthening tight muscles post-workout",
                        "Warming up joints and muscles through active movement before a workout",
                        "Increasing permanent flexibility overnight",
                        "Treating acute muscle sprains"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does VO2 max measure?",
                    options: [
                        "The maximum volume of oxygen your body can consume and use during intense exercise",
                        "Lung capacity when holding breath underwater",
                        "The speed of oxygen recovery post-exercise",
                        "Blood oxygen saturation levels at rest"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is an eccentric muscle contraction?",
                    options: [
                        "When the muscle shortens while producing force (e.g., lifting a dumbbell up)",
                        "When the muscle lengthens under tension (e.g., lowering a weight slowly)",
                        "When the muscle stays at a fixed length under load",
                        "Uncontrolled muscle spasms during fatigue"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a compound exercise?",
                    options: [
                        "An exercise that isolates a single joint and muscle (like a bicep curl)",
                        "A multi-joint movement that works several muscle groups simultaneously (like a squat or deadlift)",
                        "A workout routine combining cardio and weightlifting in one session",
                        "A movement performed on specialized gym machines"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What role do electrolytes (like sodium, potassium, magnesium) play during heavy workouts?",
                    options: [
                        "They provide the primary source of calories",
                        "They regulate fluid balance, nerve signaling, and muscle contractions",
                        "They act as a mild painkiller for sore joints",
                        "They prevent the buildup of lactic acid permanently"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Anime Illustrator" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is 'cel shading' (or toon shading) in anime art?",
                    options: [
                        "Using smooth, airbrushed color transitions for hyper-realism",
                        "Rendering shadows and highlights with crisp, hard edges and flat blocks of color",
                        "Drawing exclusively with black ink pens on transparent celluloid sheets",
                        "Applying watercolor textures to digital line art"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which digital drawing software is the industry standard in Japan for anime and manga production?",
                    options: ["Adobe InDesign", "Clip Studio Paint", "CorelDRAW", "Blender"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does the 'Multiply' layer blend mode primarily do when shading anime characters?",
                    options: [
                        "Brightens the underlying colors for glowing magic effects",
                        "Darkens the base colors underneath, making it ideal for clean shadows",
                        "Inverts all RGB color channels automatically",
                        "Turns raster line art into scalable vector paths"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'sakuga' in the context of anime production and illustration?",
                    options: [
                        "The background scenery painting department",
                        "Sequences of noticeably higher quality, fluid, and expressive animation",
                        "The process of voice acting dubbing",
                        "Merchandise character sheet formatting"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the purpose of 'subsurface scattering' (SSS) when coloring anime skin?",
                    options: [
                        "Adding metallic reflections to armor and eyes",
                        "Creating a warm, saturated red/orange edge along shadow borders to simulate light passing through skin",
                        "Blurring the background to simulate camera depth of field",
                        "Adding halftone screentone dots to clothing"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'character turnaround sheet' (Settei) used for?",
                    options: [
                        "Showing a character from front, side, and back views to maintain consistency across scenes",
                        "Listing the voice actor's script lines",
                        "Promoting the anime on billboard posters",
                        "Testing color palettes for environmental backgrounds"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "Which layer blend mode is commonly used by anime illustrators to make eyes, magic, and rim lights glow brightly?",
                    options: ["Color Burn", "Add (Glow) / Linear Dodge", "Subtract", "Divide"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why do many anime illustrators use a 'Vector Layer' specifically for line art?",
                    options: [
                        "It automatically shades the drawing in 3D",
                        "It allows adjusting line thickness, reshaping curves, and erasing intersecting lines cleanly without losing quality",
                        "It reduces the file size to under 10 kilobytes",
                        "It generates background perspectives automatically"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'rim lighting' (or backlighting) in character illustration?",
                    options: [
                        "Lighting placed directly in front of the character's face",
                        "A bright outline of light hitting the edges of a character from behind, separating them from the background",
                        "Soft ambient light coming from the floor",
                        "Shadows cast exclusively under the chin"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'chromatic aberration' often used for as a finishing touch in modern anime art?",
                    options: [
                        "Converting a colored illustration into grayscale",
                        "Slightly offsetting RGB color channels near the edges to mimic a camera lens effect",
                        "Smoothing out pixelated brush strokes",
                        "Locking transparent pixels on a layer"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Pro eSports Gamer" {
            questions = [
                QuizQuestionModel(
                    questionText: "What does 'APM' stand for in competitive real-time strategy and MOBA games?",
                    options: [
                        "Average Ping Measurement",
                        "Actions Per Minute",
                        "Attack Power Multiplier",
                        "Arena Placement Match"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'eDPI' in competitive first-person shooters?",
                    options: [
                        "Electronic Display Pixel Index",
                        "Effective Dots Per Inch (Mouse DPI multiplied by in-game sensitivity)",
                        "Enhanced Direct Performance Interface",
                        "Estimated Damage Per Impact"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'VOD review' in professional eSports coaching?",
                    options: [
                        "Testing new gaming monitors for motion blur",
                        "Analyzing recorded gameplay footage to identify positioning, macro, and decision-making mistakes",
                        "Reviewing tournament sponsor contracts",
                        "Streaming live to fans while answering Q&A"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'macro' refer to in competitive team games like League of Legends or Dota 2?",
                    options: [
                        "Individual mechanical skill and button-pressing speed",
                        "Map-wide strategy, objective control, wave management, and team rotations",
                        "Using illegal third-party scripts to automate combos",
                        "Adjusting monitor brightness and contrast settings"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why do pro FPS players prefer high refresh rate monitors (240Hz - 540Hz) with low response times?",
                    options: [
                        "To make cinematic cutscenes look more colorful",
                        "To reduce input lag and motion blur, allowing faster visual reaction to enemy movement",
                        "To increase the maximum frame rate generated by the GPU",
                        "To save electricity during long bootcamp sessions"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'peeker's advantage' in online tactical shooters?",
                    options: [
                        "Using a sniper scope to see through smoke grenades",
                        "The brief network latency window where a player swinging around a corner sees a stationary defender first",
                        "Having a coach watch the enemy team's screen",
                        "Standing on a teammate's head to look over a wall"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'tilting' in competitive gaming psychology?",
                    options: [
                        "Leaning forward in a gaming chair during intense moments",
                        "A state of emotional frustration that causes a player to make impulsive, suboptimal decisions",
                        "Rotating the keyboard at a 45-degree angle on the desk",
                        "Forfeiting a match in the first five minutes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'scrim' (scrimmage) in professional eSports?",
                    options: [
                        "An official public tournament match with prize money",
                        "A private practice match scheduled between two competitive teams to test strategies",
                        "A solo ranked matchmaking game",
                        "A warm-up aim training routine"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'frame data' crucial for in competitive fighting games (like Street Fighter or Tekken)?",
                    options: [
                        "Measuring internet packet loss during online matches",
                        "Knowing the exact startup, active, and recovery frames of attacks to punish unsafe moves",
                        "Calculating GPU temperature under heavy load",
                        "Designing custom arcade fightsticks"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'IGL' stand for in tactical team rosters?",
                    options: [
                        "International Gaming League",
                        "In-Game Leader (the player calling strategies and mid-round adjustments)",
                        "Instant Graphics Latency",
                        "Individual Game Level"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Yoga & Mindfulness Guru" {
            questions = [
                QuizQuestionModel(
                    questionText: "What does the Sanskrit word 'Pranayama' refer to in yoga practice?",
                    options: [
                        "Physical postures and stretches",
                        "Breath control and regulation of life force energy",
                        "Chanting mantras in a group",
                        "Deep relaxation at the end of class"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which yoga style is characterized by a fixed sequence of postures synchronized with the breath, flowing dynamically from one pose to the next?",
                    options: ["Yin Yoga", "Restorative Yoga", "Vinyasa Flow", "Yoga Nidra"],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is 'Savasana' (Corpse Pose) primarily intended for at the end of a session?",
                    options: [
                        "Building core and upper-body strength",
                        "Deep physical and mental integration, calming the nervous system",
                        "Stretching the hamstrings and lower back",
                        "Improving single-leg balance"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "How does Yin Yoga differ from active styles like Ashtanga or Power Yoga?",
                    options: [
                        "It is practiced in a room heated to 40°C (105°F)",
                        "Passive floor poses are held for 3 to 5 minutes to target deep connective tissues (fascia, ligaments)",
                        "It focuses exclusively on handstands and arm balances",
                        "It involves rapid cardio movements between poses"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'Ujjayi' breathing (often called Ocean Breath)?",
                    options: [
                        "Rapid, forceful exhalations through the nose",
                        "Breathing in and out through the nose with a slight constriction at the back of the throat",
                        "Holding the breath for 60 seconds after inhaling",
                        "Breathing exclusively through the mouth during cardio"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the core principle of mindfulness meditation?",
                    options: [
                        "Forcing the mind to have zero thoughts at all times",
                        "Paying intentional, non-judgmental attention to the present moment",
                        "Visualizing future financial success",
                        "Falling asleep quickly while sitting upright"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'Namaste' traditionally signify when spoken at the close of a practice?",
                    options: [
                        "Please roll up your yoga mats quietly",
                        "A respectful greeting acknowledging the light and spirit within one another",
                        "A Sanskrit term for advanced flexibility",
                        "A blessing for physical strength"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which part of the nervous system is activated by slow, deep diaphragmatic breathing?",
                    options: [
                        "The sympathetic nervous system ('fight or flight')",
                        "The parasympathetic nervous system ('rest and digest')",
                        "The somatic motor cortex exclusively",
                        "The adrenaline endocrine response"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are 'Asanas' in traditional yoga philosophy?",
                    options: [
                        "Ethical guidelines for daily living",
                        "The physical postures practiced to prepare the body for meditation",
                        "Specialized wooden yoga blocks",
                        "Dietary rules for yogis"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'Yoga Nidra' often referred to as?",
                    options: [
                        "Power acrobatic yoga",
                        "Yogic sleep — a guided meditation inducing deep conscious relaxation",
                        "Morning sun salutation sequences",
                        "Partner-assisted stretching"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Cybersecurity Specialist" {
            questions = [
                QuizQuestionModel(
                    questionText: "What do the three pillars of the 'CIA Triad' in information security stand for?",
                    options: [
                        "Cybersecurity, Intelligence, Authentication",
                        "Confidentiality, Integrity, Availability",
                        "Control, Inspection, Authorization",
                        "Cryptography, Intrusion, Auditing"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'Zero-Day' vulnerability?",
                    options: [
                        "A security flaw that has already been patched for zero days",
                        "A previously unknown software vulnerability exploited by attackers before the vendor releases a fix",
                        "A virus that deletes all files at midnight",
                        "An expired SSL/TLS certificate"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "How do parameterized queries (prepared statements) prevent SQL Injection attacks?",
                    options: [
                        "They encrypt the entire database hard drive",
                        "They strictly separate SQL code structure from user-supplied data inputs",
                        "They block all incoming HTTP POST requests",
                        "They automatically ban suspicious IP addresses"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the difference between symmetric and asymmetric encryption?",
                    options: [
                        "Symmetric uses the same key for encryption and decryption; asymmetric uses a public/private key pair",
                        "Symmetric is used only for passwords; asymmetric is used only for images",
                        "Asymmetric is much faster than symmetric for encrypting huge files",
                        "Symmetric requires an internet connection; asymmetric works offline"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is 'Phishing' (specifically Spear Phishing)?",
                    options: [
                        "Flooding a server with traffic to take it offline",
                        "Targeted social engineering attacks tailored to deceive specific individuals into revealing sensitive credentials",
                        "Scanning open network ports using Nmap",
                        "Brute-forcing Wi-Fi WPA2 handshakes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does the 'Principle of Least Privilege' (PoLP) dictate?",
                    options: [
                        "Users should share a single administrator account for convenience",
                        "Users and processes should only be granted the minimum access permissions necessary to perform their tasks",
                        "All company files should be publicly readable by default",
                        "Passwords should never expire"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'Man-in-the-Middle' (MitM) attack?",
                    options: [
                        "An attacker secretly intercepting and potentially altering communications between two parties",
                        "A physical break-in to a server data center",
                        "A malware infection spread via USB flash drives",
                        "Overloading a CPU with infinite loops"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "Why are cryptographic hashes salted before storing user passwords in a database?",
                    options: [
                        "To make password verification faster for the login server",
                        "To defend against precomputed rainbow table attacks and ensure identical passwords produce different hashes",
                        "To allow administrators to decrypt user passwords if forgotten",
                        "To compress long passwords into 8 characters"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the primary goal of a DDoS (Distributed Denial of Service) attack?",
                    options: [
                        "Stealing credit card numbers silently",
                        "Overwhelming a target system or network with massive traffic from multiple sources to make it unavailable",
                        "Installing ransomware on a single workstation",
                        "Bypassing two-factor authentication"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the difference between a 'Red Team' and a 'Blue Team' in cybersecurity?",
                    options: [
                        "Red Team simulates offensive attacks to test defenses; Blue Team defends, monitors, and responds to threats",
                        "Red Team writes backend code; Blue Team designs user interfaces",
                        "Red Team handles hardware; Blue Team handles cloud servers",
                        "Red Team is internal staff; Blue Team is always external auditors"
                    ],
                    correctIndex: 0
                )
            ]
        } else if topic.title == "Manga Concept Artist" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is a 'Name' (pronounced 'neh-mu') in the manga creation workflow?",
                    options: [
                        "The final inked cover illustration",
                        "Rough storyboard thumbnails laying out panel flow, dialogue placement, and pacing",
                        "The pen name used by the mangaka",
                        "A list of sound effects (onomatopoeia)"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are 'screentones' traditionally used for in black-and-white manga?",
                    options: [
                        "Adding glowing neon colors to digital pages",
                        "Applying pre-printed or digital dot patterns and textures to create grey shades and atmosphere",
                        "Protecting original paper manuscripts from ink smudges",
                        "Measuring panel gutter margins"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which traditional dip pen nib is famous among manga artists for producing expressive, varying line weights?",
                    options: ["Ballpoint Bic nib", "G-Pen nib", "Calligraphy stub nib", "Technical drafting needle"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the standard reading direction for authentic Japanese manga panels and speech bubbles?",
                    options: [
                        "Left-to-right, top-to-bottom",
                        "Right-to-left, top-to-bottom",
                        "Bottom-to-top, left-to-right",
                        "Center-outward in a spiral"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are 'beta' (or 'beta-flash') techniques in manga inking?",
                    options: [
                        "Test prints sent to the magazine editor",
                        "Filling large areas with solid black ink, often leaving sharp white streaks for hair shine or dramatic tension",
                        "Erasing pencil sketches after inking",
                        "Drawing background buildings in 3-point perspective"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'koma-wari' in manga visual storytelling?",
                    options: [
                        "The art of panel layout and pacing to guide the reader's eye and control emotional rhythm",
                        "Designing mecha robots and weapons",
                        "Translating Japanese sound effects into English",
                        "Binding physical manga volumes"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What are 'speed lines' (shuchu-sen) primarily used to convey in manga panels?",
                    options: [
                        "Quiet, peaceful slice-of-life moments",
                        "Intense motion, sudden shock, or drawing dramatic focus toward a central subject",
                        "Flashback scenes from a character's childhood",
                        "Rainy weather effects"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'tankobon' in the manga industry?",
                    options: [
                        "A weekly anthology magazine printed on cheap paper",
                        "A standalone compiled book volume collecting multiple chapters of a single manga series",
                        "An assistant responsible for drawing backgrounds",
                        "A digital tablet stylus"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why do manga manuscript pages feature 'bleed' (tachikiri) margins extending past the trim line?",
                    options: [
                        "To give the artist extra space to test pen ink flow",
                        "To ensure artwork running off the edge of the page doesn't leave accidental white borders when trimmed",
                        "To write editor notes and page numbers",
                        "To hold the paper down with clips"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'silhouette readability' in character concept design?",
                    options: [
                        "Drawing characters exclusively in shadow",
                        "Ensuring a character is instantly recognizable by their outline shape and posture alone",
                        "Using black backgrounds behind white text",
                        "Tracing 3D models for accurate anatomy"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "VTuber Streamer" {
            questions = [
                QuizQuestionModel(
                    questionText: "Which software is the industry standard for real-time 2D VTuber model rigging and animation?",
                    options: ["Live2D Cubism", "Adobe Premiere Pro", "AutoCAD", "FL Studio"],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'rigging' mean in the context of creating a VTuber avatar?",
                    options: [
                        "Promoting a stream on social media algorithms",
                        "Setting up a digital skeleton, deformers, and physics parameters so the model moves with facial tracking",
                        "Connecting multiple monitors to a streaming PC",
                        "Designing custom chat emotes and subscriber badges"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is VTube Studio primarily used for during a livestream?",
                    options: [
                        "Editing highlight clips for YouTube Shorts",
                        "Tracking the streamer's facial expressions via webcam/iPhone and animating the Live2D model in real time",
                        "Managing PayPal donations and merchandise orders",
                        "Hosting multiplayer voice chat servers"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'debut stream' in VTuber culture?",
                    options: [
                        "The final stream before a creator retires their character",
                        "A heavily promoted first official broadcast introducing the character's lore, voice, and model to the audience",
                        "A casual unannounced test stream with no microphone",
                        "A charity marathon lasting 24 hours"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why do many VTubers use an iPhone with Face ID (ARKit) instead of a standard USB webcam for face tracking?",
                    options: [
                        "iPhones automatically translate speech into Japanese",
                        "TrueDepth infrared sensors capture far more granular facial blendshapes (wink, cheek puff, tongue out) with lower latency",
                        "Standard webcams cannot record in 1080p resolution",
                        "ARKit removes the need for a streaming PC"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'PNGTuber'?",
                    options: [
                        "A VTuber who uses full-body VR motion capture suits",
                        "A virtual creator who uses static or reactive 2D images that switch states when speaking instead of a rigged Live2D/3D model",
                        "A streamer who exclusively plays retro pixel-art games",
                        "An AI-generated voice synthesizer bot"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What file format is the universal standard for 3D humanoid VTuber avatars across apps like VSeeFace and VRChat?",
                    options: [".VRM", ".MP3", ".PSD", ".RAW"],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is a 'graduating' (graduation) announcement in the VTuber industry?",
                    options: [
                        "Completing a university degree while streaming part-time",
                        "The formal retirement of a VTuber persona and cessation of activities under that character",
                        "Upgrading from a 2D avatar to a 3D model",
                        "Reaching 1 million subscribers on YouTube"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the role of 'overlay assets' and 'stinger transitions' in OBS Studio for VTubers?",
                    options: [
                        "To block stream snipers in competitive multiplayer games",
                        "To visually frame the broadcast screen, display chat/alerts, and smoothly transition between scenes",
                        "To boost microphone audio gain automatically",
                        "To compress video bitrate for slower internet connections"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'kayfabe' in VTubing?",
                    options: [
                        "A popular rhythm game played on stream",
                        "Maintaining the illusion and staying in-character within the fictional lore of the virtual avatar",
                        "A hardware capture card used for console streaming",
                        "A copyright strike system on Twitch"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Sommelier" {
            questions = [
                QuizQuestionModel(
                    questionText: "What does the French wine term 'terroir' encompass?",
                    options: [
                        "The specific shape of the wine bottle and cork",
                        "The complete natural environment where grapes grow, including soil, climate, topography, and sunlight",
                        "The aging duration inside stainless steel tanks",
                        "The chemical preservatives added during bottling"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are 'tannins' in wine, and where do they primarily come from?",
                    options: [
                        "Natural sugars found in sweet dessert wines",
                        "Polyphenolic compounds from grape skins, seeds, stems, and oak barrels that create a dry, astringent sensation",
                        "Carbon dioxide bubbles trapped during secondary fermentation",
                        "Artificial flavoring agents added to cheap red wines"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the primary purpose of decanting an older red wine?",
                    options: [
                        "To chill the wine rapidly before serving",
                        "To separate the clear wine from natural sediment and allow it to aerate and open its aromas",
                        "To increase the alcohol by volume (ABV) percentage",
                        "To remove residual sulfites completely"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which grape variety is exclusively used to make traditional Red Burgundy (Bourgogne)?",
                    options: ["Cabernet Sauvignon", "Pinot Noir", "Merlot", "Syrah"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'malolactic fermentation' (MLF) in winemaking?",
                    options: [
                        "Converting grape sugars into alcohol using wild yeast",
                        "A secondary bacterial process that converts sharp malic acid into softer, creamier lactic acid",
                        "Freezing grapes on the vine to concentrate sugars",
                        "Filtering wine through crushed limestone"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What causes 'cork taint' (TCA) in a bottle of wine?",
                    options: [
                        "Storing the bottle upright in a warm room",
                        "A chemical compound (2,4,6-trichloroanisole) that gives the wine a musty, wet cardboard smell",
                        "Leaving the wine open in the fridge for two days",
                        "Harvesting grapes during a rainy season"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the 'Méthode Champenoise' (Traditional Method) for sparkling wine?",
                    options: [
                        "Injecting carbon dioxide gas directly into still white wine",
                        "Inducing a secondary alcoholic fermentation inside the individual sealed bottle to create natural bubbles",
                        "Fermenting wine inside pressurized giant steel tanks (Charmat method)",
                        "Adding sparkling mineral water before corking"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'Brut' indicate on a bottle of Champagne or sparkling wine?",
                    options: [
                        "The wine is sweet and meant for dessert",
                        "The wine is dry, with very low residual sugar (under 12 grams per liter)",
                        "The wine was aged for at least 15 years",
                        "The wine is made exclusively from red grapes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why are wine bottles stored horizontally in a cellar?",
                    options: [
                        "To save vertical shelf space in restaurants",
                        "To keep the cork moist and swollen so air cannot seep in and oxidize the wine",
                        "To prevent the glass label from peeling off",
                        "To speed up the aging process"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What are the 'legs' or 'tears' seen on the inside of a wine glass after swirling?",
                    options: [
                        "An indicator of the wine's age and vintage quality",
                        "Droplets caused by the Marangoni effect, reflecting alcohol and sugar viscosity rather than quality",
                        "Residual soap left inside the glass after washing",
                        "Tiny sediment particles floating to the rim"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Barista & Coffee Roaster" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is the 'first crack' during the coffee roasting process?",
                    options: [
                        "When green coffee beans break inside the grinder blades",
                        "An audible popping sound caused by water vapor and gases escaping as the bean expands under heat",
                        "When the roaster drum overheats and fractures",
                        "Cracking open roasted beans to check internal moisture"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'channeling' during espresso extraction?",
                    options: [
                        "Pouring steamed milk into two cups simultaneously",
                        "Water finding a path of least resistance through cracks or uneven tamping in the coffee puck, causing uneven extraction",
                        "Pre-heating the portafilter with hot grouphead water",
                        "Switching between single and double shot baskets"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "How do 'washed' (wet) and 'natural' (dry) coffee processing methods differ?",
                    options: [
                        "Washed removes the fruit cherry before drying for cleaner acidity; natural dries the whole cherry intact for sweeter, fruitier notes",
                        "Washed uses soap to clean beans; natural uses rainwater only",
                        "Washed is only used for Robusta; natural is only used for Arabica",
                        "Natural coffee is roasted twice; washed coffee is roasted once"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'dialing in' an espresso grinder involve?",
                    options: [
                        "Cleaning the burrs with compressed air every morning",
                        "Adjusting grind size, dose, and yield to hit the ideal extraction time and balanced flavor profile",
                        "Setting the digital clock on the espresso machine",
                        "Weighing empty ceramic cups before service"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'crema' on top of a freshly pulled espresso shot?",
                    options: [
                        "A splash of steamed heavy cream added by the barista",
                        "A golden-brown emulsified foam of coffee oils, proteins, and CO2 gas bubbles created under high pressure",
                        "Undissolved sugar floating to the surface",
                        "Burnt coffee grounds pushed through the filter"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the key difference between a Flat White and a Caffè Latte?",
                    options: [
                        "A Flat White is served iced; a Latte is always hot",
                        "A Flat White has a higher espresso-to-milk ratio and a thinner layer of velvety microfoam",
                        "A Latte uses dark roast; a Flat White uses green unroasted beans",
                        "A Flat White contains no foam at all"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'microfoam' in milk steaming?",
                    options: [
                        "Large, airy soap-like bubbles floating on top of hot milk",
                        "Silky, glossy steamed milk with microscopic, uniform bubbles ideal for latte art",
                        "Cold milk frothed with a handheld battery whisk",
                        "Condensed milk mixed with espresso"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "How does Arabica coffee generally compare to Robusta coffee?",
                    options: [
                        "Arabica grows at higher altitudes, has higher acidity/aromatic complexity, and contains about half the caffeine of Robusta",
                        "Arabica is much more bitter and contains twice as much caffeine as Robusta",
                        "Robusta is considered specialty-grade while Arabica is used strictly for instant coffee",
                        "There is no genetic or flavor difference between them"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'blooming' refer to in pour-over brewing (like V60 or Chemex)?",
                    options: [
                        "Pouring a small amount of hot water over fresh grounds first to release trapped CO2 gas before main extraction",
                        "Decorating the coffee mug with edible flowers",
                        "Letting brewed coffee cool down to room temperature",
                        "Grinding coffee beans directly into boiling water"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What causes an espresso shot to taste overly sour and thin (under-extracted)?",
                    options: [
                        "Grind size is too coarse, water temperature is too low, or extraction time is too short",
                        "Grind size is too fine and extraction ran for 50 seconds",
                        "The coffee beans were roasted too dark",
                        "The milk was steamed past 80°C"
                    ],
                    correctIndex: 0
                )
            ]
        } else if topic.title == "Art Historian" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is 'chiaroscuro' in Renaissance and Baroque painting?",
                    options: [
                        "Painting exclusively with bright pastel watercolors",
                        "The dramatic use of strong contrasts between light and dark to create volume and three-dimensional depth",
                        "Applying gold leaf backgrounds to religious icons",
                        "Breaking objects into geometric cubes from multiple angles"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'provenance' mean in the art world?",
                    options: [
                        "The chemical analysis of oil paint pigments",
                        "The documented chronology of ownership, custody, and location of an artwork since its creation",
                        "The French region where Impressionism originated",
                        "The insurance valuation of a museum collection"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which painting technique involves applying paint onto wet lime plaster so the pigment binds into the wall as it dries?",
                    options: ["Tempera", "Buon Fresco", "Impasto", "Encaustic"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which 19th-century art movement focused on capturing fleeting effects of natural light and color with visible, loose brushstrokes?",
                    options: ["Neoclassicism", "Impressionism", "Surrealism", "Minimalism"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'impasto' in painting?",
                    options: [
                        "Thinning oil paint with turpentine until it resembles watercolor",
                        "Laying paint onto a surface so thickly that brush or palette knife strokes remain visible in three-dimensional relief",
                        "Transferring a charcoal sketch onto canvas using pinholes",
                        "Varnishing an old painting to restore its shine"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'iconography' in art historical analysis?",
                    options: [
                        "The study of visual symbols, motifs, and allegorical meanings within a work of art",
                        "Designing mobile app icons for museum audio guides",
                        "Restoring damaged wooden picture frames",
                        "Measuring the golden ratio proportions of sculptures"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "Who pioneered Cubism alongside Pablo Picasso in the early 20th century?",
                    options: ["Claude Monet", "Georges Braque", "Salvador Dalí", "Henri Matisse"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'sfumato', a technique famously mastered by Leonardo da Vinci?",
                    options: [
                        "Outlining figures with thick black ink borders",
                        "Subtle, smoky transitions between colors and tones without harsh outlines",
                        "Carving marble statues using power drills",
                        "Painting portraits exclusively in profile view"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What characterizes 'Contrapposto' in classical Greek and Renaissance sculpture?",
                    options: [
                        "Figures standing rigidly symmetrical with both feet flat",
                        "A naturalistic stance where weight rests on one leg, causing the shoulders and hips to counter-tilt",
                        "Sculptures carved entirely out of dark bronze",
                        "Abstract geometric shapes suspended from wires"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is a 'triptych'?",
                    options: [
                        "A three-legged wooden easel used outdoors",
                        "A work of art (typically an altarpiece) divided into three hinged or adjacent panels",
                        "A pigment made from crushed lapis lazuli",
                        "A 1960s Pop Art printing technique"
                    ],
                    correctIndex: 1
                )
            ]
        } else if topic.title == "Sound Producer" {
            questions = [
                QuizQuestionModel(
                    questionText: "What does 'Nyquist Theorem' dictate in digital audio recording?",
                    options: [
                        "Microphones must be placed at least 2 feet from acoustic guitars",
                        "The sample rate must be at least twice the highest frequency you wish to accurately capture (e.g., 44.1 kHz for 20 kHz audio)",
                        "Subwoofers should always be panned hard left",
                        "Audio cables cannot exceed 10 meters without losing stereo width"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does 'bit depth' (e.g., 16-bit vs 24-bit) primarily determine in digital audio?",
                    options: [
                        "The maximum frequency range in Hertz",
                        "The dynamic range and signal-to-noise floor resolution of the recording",
                        "The tempo (BPM) accuracy of MIDI tracks",
                        "The number of audio tracks a DAW can play simultaneously"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'phase cancellation' when recording with multiple microphones?",
                    options: [
                        "When two microphones are muted at the same time",
                        "When identical sound waves arrive out of alignment, causing frequencies to cancel out and sound thin or hollow",
                        "When phantom power (+48V) damages a ribbon microphone",
                        "When reverb tails clash with the bassline"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does the 'ratio' parameter on an audio compressor control?",
                    options: [
                        "How fast the compressor reacts after the signal crosses the threshold",
                        "The amount of gain reduction applied once the input signal exceeds the threshold (e.g., 4:1)",
                        "The stereo width of the compressed track",
                        "The high-pass filter cutoff frequency"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Why do sound engineers use a High-Pass Filter (HPF) on non-bass instruments like vocals, guitars, and hi-hats?",
                    options: [
                        "To boost sub-bass frequencies below 60 Hz",
                        "To remove unnecessary low-end rumble and mud, leaving clean headroom for the kick and bass",
                        "To add tape saturation warmth to highs",
                        "To convert stereo tracks into mono"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'LUFS' used to measure in modern audio mixing and mastering?",
                    options: [
                        "Cable impedance in Ohms",
                        "Perceived loudness units relative to full scale, standardized for streaming platforms and broadcast",
                        "Microphone diaphragm sensitivity",
                        "CPU usage of VST plugins"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the key difference between a condenser microphone and a dynamic microphone?",
                    options: [
                        "Condenser mics require phantom power (+48V) and offer high sensitivity/detail; dynamic mics are rugged, passive, and handle high SPLs well",
                        "Dynamic mics require +48V phantom power; condenser mics work via Bluetooth",
                        "Condenser mics are only for drums; dynamic mics are strictly for acoustic violins",
                        "Dynamic mics record in stereo; condenser mics only record in mono"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is 'Mid-Side (M/S) EQ' processing?",
                    options: [
                        "Equalizing the middle and end sections of a song differently",
                        "Independently processing the center (mono/sum) signal and the stereo side (difference) signal",
                        "Boosting mid-range frequencies at 1 kHz exclusively",
                        "Aligning MIDI notes to the grid"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'headroom' in audio engineering?",
                    options: [
                        "The physical ceiling height of a recording booth",
                        "The safety margin in decibels between the peak level of an audio signal and 0 dBFS digital clipping",
                        "The space inside open-back studio headphones",
                        "The pre-delay time on a hall reverb"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'parallel compression' (New York compression)?",
                    options: [
                        "Compressing two identical vocal takes side-by-side",
                        "Blending an unprocessed dry signal with a heavily compressed copy of the same signal to add punch while preserving transients",
                        "Putting five compressors in series on the master bus",
                        "Using a limiter to block peaks above -0.1 dB"
                    ],
                    correctIndex: 1
                )
            ]
        } else {
            // Заглушка-рандомизатор для остальных топиков (если понадобятся)
            questions = [
                QuizQuestionModel(questionText: "What is the core principle when working as a \(topic.title)?", options: ["Consistency and Practice", "Pure Luck", "Ignoring Feedback", "Working 2 hours a week"], correctIndex: 0),
                QuizQuestionModel(questionText: "Which tool or technique is most commonly used first?", options: ["Advanced Automation", "Basic Fundamentals", "Random Guessing", "Complex Frameworks"], correctIndex: 1),
                QuizQuestionModel(questionText: "How do professionals handle critical blockers?", options: ["Panic and Quit", "Analyze, Debug, and Iterate", "Blame the client", "Delete everything"], correctIndex: 1),
                QuizQuestionModel(questionText: "What defines a true expert in this field?", options: ["Years of continuous learning", "Having a fancy title", "Expensive equipment", "Natural born talent only"], correctIndex: 0),
                QuizQuestionModel(questionText: "Which metric best shows your daily progress?", options: ["Quality of output & skill growth", "Number of coffee cups", "Hours spent sleeping", "Social media followers"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is a common beginner mistake to avoid?", options: ["Skipping basics for shortcuts", "Asking questions", "Practicing daily", "Taking notes"], correctIndex: 0),
                QuizQuestionModel(questionText: "How should you approach complex tasks?", options: ["Break them down into smaller steps", "Do them all at midnight", "Hope they resolve themselves", "Ignore them"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is the best way to receive constructive feedback?", options: ["Take it and adapt", "Get defensive", "Ignore it completely", "Argue back"], correctIndex: 0),
                QuizQuestionModel(questionText: "What role does creativity play here?", options: ["Crucial for innovative solutions", "None at all", "Only on weekends", "Only for marketing"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is the ultimate goal of mastering this craft?", options: ["Creating value and mastering skills", "Making fast money with zero effort", "Impressing friends on Instagram", "Passing time"], correctIndex: 0)
            ].shuffled()
        }
    }
    
    func validateAnswer(selectedIdx: Int) -> Bool {
        guard let question = currentQuestion else { return false }
        let isCorrect = (selectedIdx == question.correctIndex)
        if isCorrect {
            score += 1
        }
        return isCorrect
    }
    
    func nextQuestion() -> Bool {
        currentQuestionIndex += 1
        return currentQuestionIndex < questions.count
    }
}
