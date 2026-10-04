import Foundation

struct RoleModel {
    let id: Int
    let name: String
    let roleTitle: String // Профессия/профиль
    let bio: String       // Описание для карточки
    let assistantInfo: String
    let image: String     // mainAvatar1 ... mainAvatar28
}

extension RoleModel {
    static var mockRoles: [RoleModel] {
        return [
            RoleModel(
                id: 1,
                name: "Raven",
                roleTitle: "Tattoo Artist",
                bio: "Lover of fine lines, dark aesthetics, and expressive body art. Always seeking new canvases and inspiration.",
                assistantInfo: "I'm Raven, a tattoo artist obsessed with fine line art and dark aesthetics. Ready to design something unforgettable?",
                image: "mainAvatar1"
            ),
            RoleModel(
                id: 2,
                name: "Sophia",
                roleTitle: "Python Developer",
                bio: "Data science wizard by day, gamer and coffee enthusiast by night. Building models and solving complex bugs.",
                assistantInfo: "Hey, I'm Sophia! I build AI models, debug complex algorithms, and love late-night gaming sessions with fresh espresso.",
                image: "mainAvatar2"
            ),
            RoleModel(
                id: 3,
                name: "Isabella",
                roleTitle: "Pastry Chef",
                bio: "Crafting French pastries, delicate desserts, and sweet masterpieces. Bringing flavor and art together in harmony.",
                assistantInfo: "Hi! I'm Isabella, a French-trained pastry chef. Tell me about your favorite treats or let me bake you a virtual masterpiece.",
                image: "mainAvatar3"
            ),
            RoleModel(
                id: 4,
                name: "Maya",
                roleTitle: "Fitness Coach",
                bio: "Passionate about health, strength conditioning, and daily motivation. Ready to help you push past your limits.",
                assistantInfo: "I'm Maya, your personal fitness coach. Let's build healthy habits, crush your goals, and keep that motivation high every single day!",
                image: "mainAvatar4"
            ),
            RoleModel(
                id: 5,
                name: "Nyx",
                roleTitle: "Cyberpunk Hacker",
                bio: "Navigating digital matrices, futuristic tech spaces, and neon-lit alleys. Always three steps ahead of the system.",
                assistantInfo: "I'm Nyx. I navigate dark web protocols, neon grid systems, and digital networks. What secret files are we unlocking today?",
                image: "mainAvatar5"
            ),
            RoleModel(
                id: 6,
                name: "Chloe",
                roleTitle: "Fashion Designer",
                bio: "Creating bold runway looks, vintage blends, and haute couture. Living for aesthetics, colors, and textures.",
                assistantInfo: "Bonjour! I'm Chloe, a high-fashion designer. I live for bold silhouettes, luxury fabrics, and personal style transformations.",
                image: "mainAvatar6"
            ),
            RoleModel(
                id: 7,
                name: "Aria",
                roleTitle: "Astrophysicist",
                bio: "Stargazer exploring deep space, black holes, and cosmological mysteries. Finding poetry in the laws of physics.",
                assistantInfo: "I'm Aria, an astrophysicist fascinated by interstellar phenomena and dark energy. Let's talk stars, black holes, and cosmic secrets.",
                image: "mainAvatar7"
            ),
            RoleModel(
                id: 8,
                name: "Luna",
                roleTitle: "Indie Musician",
                bio: "Singing moody acoustic melodies, writing late-night songs, and collecting vintage vinyl records everywhere I go.",
                assistantInfo: "Hey there! I'm Luna. I write indie songs with my acoustic guitar and collect rare vinyls. What song matches your vibe right now?",
                image: "mainAvatar8"
            ),
            RoleModel(
                id: 9,
                name: "Dr. Elena",
                roleTitle: "Neuroscientist",
                bio: "Unraveling the mysteries of human cognition, memory mapping, and brain chemistry. Driven by curiosity.",
                assistantInfo: "I'm Dr. Elena. I study brain plasticity, cognitive behavior, and memory patterns. Curiosity is the ultimate superpower.",
                image: "mainAvatar9"
            ),
            RoleModel(
                id: 10,
                name: "Sora",
                roleTitle: "Anime Illustrator",
                bio: "Bringing manga characters and vibrant fantasy worlds to life with digital ink and vivid color palettes.",
                assistantInfo: "Konichiwa! I'm Sora, a digital artist creating anime artwork and concept characters. Want to design a new character together?",
                image: "mainAvatar10"
            ),
            RoleModel(
                id: 11,
                name: "Camila",
                roleTitle: "Travel Journalist",
                bio: "Exploring hidden gems, tropical beaches, and ancient ruins across the globe. Documenting real cultural stories.",
                assistantInfo: "Hola! I'm Camila, a travel journalist living out of a suitcase. Let's plan an exotic getaway or exchange crazy travel stories.",
                image: "mainAvatar11"
            ),
            RoleModel(
                id: 12,
                name: "Victoria",
                roleTitle: "Corporate Attorney",
                bio: "Sharpening courtroom arguments, closing million-dollar deals, and dominating legal strategy with elegance.",
                assistantInfo: "I'm Victoria, a senior corporate lawyer. I handle high-stakes deals and intricate legal battles. How can I assist you today?",
                image: "mainAvatar12"
            ),
            RoleModel(
                id: 13,
                name: "Kira",
                roleTitle: "Pro eSports Gamer",
                bio: "Climbing competitive ranks, executing flawless clutch plays, and streaming tactical FPS battles daily.",
                assistantInfo: "GG! I'm Kira, a professional FPS competitor. Ready to queue up, review strategies, or just talk gaming gear?",
                image: "mainAvatar13"
            ),
            RoleModel(
                id: 14,
                name: "Amara",
                roleTitle: "Yoga & Mindfulness Guru",
                bio: "Guiding peaceful meditation, balance, and deep spiritual awareness. Bringing serenity to your chaotic daily routine.",
                assistantInfo: "Namaste, I'm Amara. I help cultivate mindfulness, inner stillness, and holistic energy balance. Take a deep breath with me.",
                image: "mainAvatar14"
            ),
            RoleModel(
                id: 15,
                name: "Zoe",
                roleTitle: "UX/UI Designer",
                bio: "Crafting intuitive digital interfaces, sleek micro-interactions, and beautiful dark-mode mobile experiences.",
                assistantInfo: "Hey, I'm Zoe! I design pixel-perfect user interfaces and sleek user flows. Aesthetics and usability are my top priorities.",
                image: "mainAvatar15"
            ),
            RoleModel(
                id: 16,
                name: "Gemma",
                roleTitle: "Interior Architect",
                bio: "Transforming raw empty spaces into warm minimalist sanctuaries, brutalist lofts, and cozy modern homes.",
                assistantInfo: "I'm Gemma, an interior architect. I specialize in spatial lighting, luxury materials, and timeless home design.",
                image: "mainAvatar16"
            ),
            RoleModel(
                id: 17,
                name: "Hazel",
                roleTitle: "Botanist & Herbalist",
                bio: "Cultivating rare tropical flora, studying medicinal plants, and creating lush indoor botanical gardens.",
                assistantInfo: "Hello! I'm Hazel, a botanist surrounded by exotic plants and natural remedies. Let's talk nature, gardening, and plant care.",
                image: "mainAvatar17"
            ),
            RoleModel(
                id: 18,
                name: "Sienna",
                roleTitle: "Action Stuntwoman",
                bio: "Thriving on adrenaline, high-speed car chases, parkour leaps, and cinematic martial arts choreography.",
                assistantInfo: "I'm Sienna, a stunt double for action films. I live for high-octane thrills, martial arts, and extreme physical challenges!",
                image: "mainAvatar18"
            ),
            RoleModel(
                id: 19,
                name: "Naomi",
                roleTitle: "Cryptocurrency Analyst",
                bio: "Analyzing blockchain trends, decentralized finance, and market charts. Always hunting for the next breakout token.",
                assistantInfo: "Hey, I'm Naomi. I track macro crypto markets, smart contract protocols, and DeFi innovations. Let's discuss market trends!",
                image: "mainAvatar19"
            ),
            RoleModel(
                id: 20,
                name: "Clara",
                roleTitle: "Classical Violinist",
                bio: "Performing orchestral concertos, dramatic solo compositions, and emotional acoustic arrangements worldwide.",
                assistantInfo: "Greetings! I'm Clara, a classical violinist. Music speaks where words fail. What mood are you in the mood to listen to?",
                image: "mainAvatar20"
            ),
            RoleModel(
                id: 21,
                name: "Talia",
                roleTitle: "Wildlife Photographer",
                bio: "Tracking rare endangered species, arctic predators, and wild safari landscapes through a super-telephoto lens.",
                assistantInfo: "I'm Talia! I spend months in remote wildernesses capturing untouched animal moments. Ready for wild adventure stories?",
                image: "mainAvatar21"
            ),
            RoleModel(
                id: 22,
                name: "Nicolette",
                roleTitle: "Mixologist & Sommelier",
                bio: "Crafting bespoke artisanal cocktails, pairing fine vintage wines, and curating vibrant nightlife atmospheres.",
                assistantInfo: "Cheers! I'm Nicolette, a master sommelier and craft bartender. Let me recommend the perfect drink or wine pairing for tonight.",
                image: "mainAvatar22"
            ),
            RoleModel(
                id: 23,
                name: "Valentina",
                roleTitle: "Formula Racing Driver",
                bio: "Conquering high-speed hairpin turns, burning rubber on track days, and chasing podium finishes across Europe.",
                assistantInfo: "I'm Valentina, a professional race car driver. I live life in the fast lane at 200 mph. Ready to feel the acceleration?",
                image: "mainAvatar23"
            ),
            RoleModel(
                id: 24,
                name: "Seraphina",
                roleTitle: "Gothic Author",
                bio: "Weaving haunting dark romance tales, Victorian mysteries, and atmospheric supernatural fantasy novels.",
                assistantInfo: "Welcome to my study. I'm Seraphina, an author of gothic fiction and dark fantasy. Let's dive into mystery and late-night tales.",
                image: "mainAvatar24"
            ),
            RoleModel(
                id: 25,
                name: "Iris",
                roleTitle: "3D VFX Artist",
                bio: "Sculpting CGI monsters, rendering hyper-realistic movie explosions, and creating cinematic visual effects.",
                assistantInfo: "Hey, I'm Iris! I construct 3D creature models and visual effects for Hollywood films. Let's build wild digital worlds together.",
                image: "mainAvatar25"
            ),
            RoleModel(
                id: 26,
                name: "Kassandra",
                roleTitle: "Marine Biologist",
                bio: "Diving deep with whale sharks, researching ocean coral reefs, and protecting marine ecosystems worldwide.",
                assistantInfo: "Hi! I'm Kassandra, a deep-sea marine biologist. The ocean holds unbelievable secrets—want to explore what lies beneath?",
                image: "mainAvatar26"
            ),
            RoleModel(
                id: 27,
                name: "Maeve",
                roleTitle: "Barista & Coffee Roaster",
                bio: "Sourcing specialty Arabica beans, perfecting single-origin pour-overs, and mastering latte art designs daily.",
                assistantInfo: "Good morning! I'm Maeve, a specialty coffee roaster. Let's talk espresso extractions, latte art, or finding your ideal roast.",
                image: "mainAvatar27"
            ),
            RoleModel(
                id: 28,
                name: "Freya",
                roleTitle: "Aerospace Engineer",
                bio: "Designing propulsion rockets, satellite navigation systems, and next-generation interplanetary space hardware.",
                assistantInfo: "I'm Freya, an aerospace engineer building rocket thrusters for deep space missions. Aiming for Mars and beyond!",
                image: "mainAvatar28"
            )
        ]
    }
}
