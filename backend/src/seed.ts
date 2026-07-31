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

  console.log('✅ Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });