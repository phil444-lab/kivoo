import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding locations...');

  // Créer le Bénin
  const benin = await prisma.country.upsert({
    where: { code: 'BJ' },
    update: {},
    create: {
      name: 'Bénin',
      code: 'BJ',
      departments: {
        create: [
          { name: 'Alibori' },
          { name: 'Atakora' },
          { name: 'Atlantique' },
          { name: 'Borgou' },
          { name: 'Collines' },
          { name: 'Couffo' },
          { name: 'Donga' },
          { name: 'Littoral' },
          { name: 'Mono' },
          { name: 'Ouémé' },
          { name: 'Plateau' },
          { name: 'Zou' },
        ],
      },
    },
    include: { departments: true },
  });

  console.log(`✅ Pays créé: ${benin.name}`);

  // Villes et quartiers corrigés pour le Bénin
  const citiesData: Record<string, { cities: string[]; districts: Record<string, string[]> }> = {
    Littoral: {
      cities: ['Cotonou'],
      districts: {
        Cotonou: [
          'Akpakpa',
          'Gbegamey',
          'Cadjehoun',
          'Ganhi',
          'Dantokpa',
          'Missebo',
          'Agla',
          'Fidjrosse',
          'Vedoko',
          'Sainte Rita',
          'Saint Michel',
          'Houeyiho',
          'Zogbo',
          'Enagnon',
          'JAK',
          'Haie Vive',
          'Menontin',
        ],
      },
    },
    Ouémé: {
      cities: ['Porto-Novo', 'Sèmè-Kpodji', 'Adjarra', 'Akpro-Missérété', 'Avrankou', 'Bonou', 'Dangbo'],
      districts: {
        'Porto-Novo': ['Ouando', 'Djassin', 'Sadjatinme', 'Dowa', 'Agontoukon', 'Avassa', 'Djenon', 'Kadjola', 'Ahouangbo'],
        'Sèmè-Kpodji': ['Ekpe', 'Agblangandan', 'Seme', 'Djeffa', 'Kraké'],
        Adjarra: ['Adjarra Centre', 'Honvié', 'Malignon'],
        'Akpro-Missérété': ['Missérété Centre', 'Vakon', 'Gomè'],
      },
    },
    Atlantique: {
      cities: ['Abomey-Calavi', 'Allada', 'Ouidah', 'Kpomassè', 'Tori-Bossito', 'Sô-Ava', 'Toffo', 'Zè'],
      districts: {
        'Abomey-Calavi': ['Calavi Centre', 'Godomey', 'Kpota', 'Akassato', 'Zoca', 'Ouedo', 'Togba', 'Zinvié'],
        Ouidah: ['Ouidah Centre', 'Avlékété', 'Gakpè', 'Pahou', 'Savi'],
        Allada: ['Allada Centre', 'Séhouè', 'Ayou', 'Togoudo'],
      },
    },
    Borgou: {
      cities: ['Parakou', 'Nikki', 'Tchaourou', 'Bembèrèkè', 'Kalalé', 'N\'Dali', 'Pèrèrè', 'Sinendé'],
      districts: {
        Parakou: ['Parakou Centre', 'Banikanni', 'Titirou', 'Guéma', 'Ganou', 'Baka', 'Albarika', 'Kpébié'],
        Nikki: ['Nikki Centre', 'Bouanri', 'Sanson', 'Suya'],
        Tchaourou: ['Tchaourou Centre', 'Bétérou', 'Tchatchou'],
      },
    },
    Zou: {
      cities: ['Abomey', 'Bohicon', 'Agbangnizoun', 'Covè', 'Zogbodomey', 'Djidja', 'Ouinhi', 'Za-Kpota', 'Zagnanado'],
      districts: {
        Abomey: ['Abomey Centre', 'Sodohome', 'Djègbé', 'Hounli'],
        Bohicon: ['Bohicon Centre', 'Sodohome', 'Saclo', 'Passagon', 'Avronkou'],
      },
    },
    Mono: {
      cities: ['Lokossa', 'Athiémé', 'Bopa', 'Comè', 'Grand-Popo', 'Houéyogbé'],
      districts: {
        Lokossa: ['Lokossa Centre', 'Agamé', 'Houin', 'Koudo'],
        Comè: ['Comè Centre', 'Oumako', 'Akodéha', 'Agatogbo'],
        'Grand-Popo': ['Grand-Popo Centre', 'Avlo', 'Agoué'],
      },
    },
    Couffo: {
      cities: ['Dogbo', 'Aplahoué', 'Djakotomey', 'Klouékanmè', 'Lalo', 'Toviklin'],
      districts: {
        Dogbo: ['Dogbo Centre', 'Totchangni', 'Honton', 'Tota'],
        Aplahoué: ['Aplahoué Centre', 'Azovè', 'Godohou'],
      },
    },
    Donga: {
      cities: ['Djougou', 'Bassila', 'Copargo', 'Ouaké'],
      districts: {
        Djougou: ['Djougou Centre', 'Kolokondé', 'Bariénou', 'Onklou'],
        Bassila: ['Bassila Centre', 'Manigri', 'Aledjo'],
      },
    },
    Atakora: {
      cities: ['Natitingou', 'Tanguiéta', 'Boukoumbé', 'Matéri', 'Péhunco', 'Kérou', 'Kouandé', 'Toucountouna'],
      districts: {
        Natitingou: ['Natitingou Centre', 'Perma', 'Kouaba', 'Tchatingou'],
        Tanguiéta: ['Tanguiéta Centre', 'Nassablé', 'Cobia'],
      },
    },
    Alibori: {
      cities: ['Kandi', 'Malanville', 'Banikoara', 'Gogounou', 'Ségbana', 'Karimama'],
      districts: {
        Kandi: ['Kandi Centre', 'Gona', 'Sonsoro', 'Donwari'],
        Malanville: ['Malanville Centre', 'Garou', 'Guéné'],
        Banikoara: ['Banikoara Centre', 'Gomparou', 'Toukountouna'],
      },
    },
    Plateau: {
      cities: ['Pobè', 'Sakété', 'Adja-Ouèrè', 'Ifangni', 'Kétou'],
      districts: {
        Pobè: ['Pobè Centre', 'Issaba', 'Igana'],
        Sakété: ['Sakété Centre', 'Ita-Djèbou', 'Takon'],
        Kétou: ['Kétou Centre', 'Okpométa', 'Idigny'],
      },
    },
    Collines: {
      cities: ['Dassa-Zoumé', 'Savalou', 'Savè', 'Bantè', 'Glazoué', 'Ouèssè'],
      districts: {
        'Dassa-Zoumé': ['Dassa Centre', 'Paouingnan', 'Soclogbo', 'Lema'],
        Savalou: ['Savalou Centre', 'Tchetti', 'Doumé', 'Lèda'],
        Savè: ['Savè Centre', 'Adido', 'Plateau', 'Okpara'],
      },
    },
  };

  for (const dept of benin.departments) {
    const data = citiesData[dept.name];
    if (!data) continue;

    for (const cityName of data.cities) {
      const city = await prisma.city.create({
        data: {
          name: cityName,
          departmentId: dept.id,
        },
      });

      const cityDistricts = data.districts[cityName];
      if (cityDistricts && cityDistricts.length > 0) {
        await prisma.district.createMany({
          data: cityDistricts.map((d: string) => ({
            name: d,
            cityId: city.id,
          })),
        });
      }

      console.log(`   ✓ Ville: ${cityName} (${cityDistricts?.length || 0} quartiers)`);
    }
  }

  console.log('\n🌱 Seeding categories...');

  const categoriesData = [
    {
      name: 'Véhicules',
      subcategories: [
        'Voitures',
        'Bus & Microbus',
        'Motos & Scooters',
        'Camions & Remorques',
        'Engins lourds & Chantiers',
        'Pièces détachées & Accessoires',
        'Bateaux & Engins nautiques',
      ],
    },
    {
      name: 'Immobilier',
      subcategories: [
        'Maisons & Appartements à louer',
        'Maisons & Appartements à vendre',
        'Terrains à vendre / louer',
        'Locations courte durée / Meublés',
        'Locaux commerciaux & Bureaux',
        'Salles d\'événements & Fêtes',
      ],
    },
    {
      name: 'Téléphones & Tablettes',
      subcategories: [
        'Téléphones portables',
        'Tablettes',
        'Montres & Bracelets connectés',
        'Accessoires pour téléphones & tablettes',
      ],
    },
    {
      name: 'Électronique',
      subcategories: [
        'Ordinateurs portables & Fixes',
        'Téléviseurs & Équipements vidéo',
        'Matériel Audio & Son',
        'Accessoires informatiques',
        'Appareils photo & Caméras',
        'Jeux vidéo & Consoles',
        'Équipements réseau',
        'Logiciels',
      ],
    },
    {
      name: 'Équipement Maison',
      subcategories: [
        'Électroménager',
        'Meubles & Mobilier',
        'Décoration d\'intérieur',
        'Ustensiles de cuisine & Vaisselle',
        'Jardin & Équipements extérieurs',
      ],
    },
    {
      name: 'Fashion',
      subcategories: [
        'Vêtements',
        'Chaussures',
        'Sacs & Maroquinerie',
        'Bijoux',
        'Montres',
        'Accessoires de mode',
        'Mariage & Tenues de cérémonie',
      ],
    },
    {
      name: 'Santé & Beauté',
      subcategories: [
        'Parfums',
        'Maquillage',
        'Soins de la peau',
        'Produits & Soins capillaires',
        'Vitamines & Compléments alimentaires',
        'Équipements & Matériel médical',
        'Bien-être sexuel',
      ],
    },
    {
      name: 'Sports, Arts & Loisirs',
      subcategories: [
        'Équipements sportifs & Fitness',
        'Instruments de musique',
        'Livres, Films & Musique',
        'Artisanat & Objets d\'art',
        'Camping & Randonnée',
      ],
    },
    {
      name: 'Bébés & Enfants',
      subcategories: [
        'Soins & Équipements bébé',
        'Vêtements enfant',
        'Chaussures enfant',
        'Poussettes & Lits bébé',
        'Jouets & Jeux d\'éveil',
      ],
    },
    {
      name: 'Animaux',
      subcategories: [
        'Chiens & Chiots',
        'Chats & Chatons',
        'Oiseaux',
        'Poissons & Aquariums',
        'Nourriture & Accessoires pour animaux',
      ],
    },
    {
      name: 'Services',
      subcategories: [
        'Services auto & Transport',
        'BTP, Rénovation & Artisanat',
        'Nettoyage & Entretien',
        'Services informatiques & Tech',
        'Événementiel & Traiteurs',
        'Dépannage & Réparation',
        'Services juridiques & Financiers',
      ],
    },
    {
      name: 'Équipements Professionnels & Industriels',
      subcategories: [
        'Machinerie & Lignes de production',
        'Matériel de Restauration & Hôtellerie',
        'Mobilier & Équipement de bureau',
        'Imprimerie & Fournitures',
      ],
    },
    {
      name: 'Agriculture & Alimentation',
      subcategories: [
        'Machines & Outils agricoles',
        'Semences, Engrais & Aliments pour bétail',
        'Élevage & Volaille',
        'Produits alimentaires & Boissons',
      ],
    },
    {
      name: 'Emplois & Candidatures',
      subcategories: [
        'Offres d\'emploi',
        'Demandes d\'emploi / Base de CV',
      ],
    },
  ];

  for (const cat of categoriesData) {
    const parent = await prisma.category.upsert({
      where: { name: cat.name },
      update: {},
      create: { name: cat.name },
    });

    for (const subName of cat.subcategories) {
      await prisma.category.upsert({
        where: { name: subName },
        update: { parentCategoryId: parent.id },
        create: { name: subName, parentCategoryId: parent.id },
      });
    }

    console.log(`   ✓ ${cat.name} (${cat.subcategories.length} sous-catégories)`);
  }

  console.log('✅ Seed completed successfully!');

  console.log('\n🌱 Seeding featured options...');

  const featuredData = [
    {
      title: 'Offres Premium',
      subtitle: 'Jusqu\'à -60%',
      icon: 'gift',
      borderColor: '#4f8ef7',
      darkBg: '#142035',
      lightBg: '#deeaff',
      order: 0,
    },
    {
      title: 'Nouveautés',
      subtitle: 'Fraîchement arrivé',
      icon: 'star',
      borderColor: '#22c55e',
      darkBg: '#0f2718',
      lightBg: '#dcfce7',
      order: 1,
    },
    {
      title: 'Grandes Marques',
      subtitle: 'Vendeurs vérifiés',
      icon: 'circle-check',
      borderColor: '#f59e0b',
      darkBg: '#241a06',
      lightBg: '#fef3c7',
      order: 2,
    },
    {
      title: 'Soldes Flash',
      subtitle: 'Édition limitée',
      icon: 'bolt',
      borderColor: '#a855f7',
      darkBg: '#1c0e34',
      lightBg: '#f3e8ff',
      order: 3,
    },
  ];

  await prisma.featuredOption.createMany({
    data: featuredData,
    skipDuplicates: true,
  });
  console.log(`   ✓ ${featuredData.length} options insérées`);

  console.log('✅ Featured options seeded!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });