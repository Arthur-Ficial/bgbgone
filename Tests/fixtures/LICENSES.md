# Image registry

Single source of truth for every image in `Tests/fixtures/`. One row per
file. `scripts/lint-fixtures.sh` fails the build if a file is missing
from this table or a row points at a missing file.

## Policy

| Tier | Licences allowed | Used for |
|------|------------------|----------|
| **Core** (`tier: pd`) | Public domain only (PD-NASA, PD-USGov, PD-old, PD-Art) | e2e integration tests |
| **Demo** (`tier: cc0`) | CC0 1.0 (public-domain dedication) | Showcase / README / per-filter docs |
| **Owner** (`tier: own`) | CC BY 4.0, own work by project owner | Showcase portrait |

CC0 is equivalent to public-domain dedication and unencumbered for any
use, including redistribution and derivative use. No attribution-required
third-party imagery ships in this repo.

## Registry

| File | Tier | Licence | Source | Attribution |
|------|------|---------|--------|-------------|
| `aldrin-on-moon.jpg` | pd | PD-NASA | [Aldrin_Apollo_11_original.jpg](https://commons.wikimedia.org/wiki/File:Aldrin_Apollo_11_original.jpg) | Neil Armstrong, NASA, 1969 |
| `apollo11-crew.jpg` | pd | PD-NASA | [Apollo_11_Crew.jpg](https://commons.wikimedia.org/wiki/File:Apollo_11_Crew.jpg) | NASA, 1969 |
| `astronaut-eva.jpg` | pd | PD-NASA | [Astronaut-EVA.jpg](https://commons.wikimedia.org/wiki/File:Astronaut-EVA.jpg) | NASA, STS-41-B, 1984 |
| `car-ad.jpg` | pd | PD-old/1929 | [Pierce_Arrow_advertisement_(1909).jpg](https://commons.wikimedia.org/wiki/File:Pierce_Arrow_advertisement_(1909).jpg) | Pierce-Arrow Motor Car Co., 1909 |
| `corgi-puppy.jpg` | cc0 | CC0 1.0 | [Pixabay 3389729](https://commons.wikimedia.org/wiki/File:Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg) | Huoadg5888, 2016 |
| `earthrise.jpg` | pd | PD-NASA | [NASA-Apollo8-Dec24-Earthrise.jpg](https://commons.wikimedia.org/wiki/File:NASA-Apollo8-Dec24-Earthrise.jpg) | William Anders, NASA, 1968 |
| `einstein.jpg` | pd | PD-old/1929 | [Einstein_1921_by_F_Schmutzer](https://commons.wikimedia.org/wiki/File:Einstein_1921_by_F_Schmutzer_-_restoration.jpg) | Ferdinand Schmutzer, 1921 |
| `galaxy-ngc1300.jpg` | pd | PD-NASA / PD-Hubble | [Hubble2005-01-barred-spiral-galaxy-NGC1300.jpg](https://commons.wikimedia.org/wiki/File:Hubble2005-01-barred-spiral-galaxy-NGC1300.jpg) | NASA/ESA Hubble Heritage Team |
| `great-wave.jpg` | pd | PD-old | [The_Great_Wave_off_Kanagawa.jpg](https://commons.wikimedia.org/wiki/File:The_Great_Wave_off_Kanagawa.jpg) | Katsushika Hokusai, c.1831 |
| `kingfisher.jpg` | cc0 | CC0 1.0 | [Eisvogel_kingfisher.jpg](https://commons.wikimedia.org/wiki/File:Eisvogel_kingfisher.jpg) | Frank-2.0, 2016 |
| `man-with-pipe.jpg` | cc0 | CC0 1.0 | [Pixabay 3013924](https://commons.wikimedia.org/wiki/File:Bearded_man_smoking_pipe-3013924.jpg) | ThuyHaBich, 2018 |
| `mars-rover.jpg` | pd | PD-NASA | [Curiosity Self-Portrait](https://commons.wikimedia.org/wiki/File:Curiosity_Self-Portrait_at_%27Big_Sky%27_Drilling_Site.jpg) | NASA/JPL-Caltech/MSSS, 2015 |
| `matterhorn-sunset.jpg` | cc0 | CC0 1.0 | [Matterhorn sunset 2016 (Unsplash)](https://commons.wikimedia.org/wiki/File:Matterhorn_sunset_2016_(Unsplash).jpg) | Sam Ferrara, Unsplash, 2016 |
| `mona-lisa.jpg` | pd | PD-Art | [Mona_Lisa, by Leonardo da Vinci](https://commons.wikimedia.org/wiki/File:Mona_Lisa,_by_Leonardo_da_Vinci,_from_C2RMF_retouched.jpg) | Leonardo da Vinci, c.1503 |
| `nebula-flaming-star.png` | cc0 | CC0 1.0 | [Flaming Star Nebula, IC 405](https://commons.wikimedia.org/wiki/File:Flaming_Star_Nebula,_IC_405.png) | Chuck Ayoub, 2025 |
| `nebula-flying-dragon.png` | cc0 | CC0 1.0 | [Flying-Dragon-Nebula Sh 2-113](https://commons.wikimedia.org/wiki/File:Flying-Dragon-Nebula_Sh_2-113.png) | Chuck Ayoub, 2024 |
| `pearl-earring.jpg` | pd | PD-Art | [1665_Girl_with_a_Pearl_Earring.jpg](https://commons.wikimedia.org/wiki/File:1665_Girl_with_a_Pearl_Earring.jpg) | Johannes Vermeer, c.1665 |
| `phonograph.jpg` | pd | PD-old | [Edison_and_phonograph_edit2.jpg](https://commons.wikimedia.org/wiki/File:Edison_and_phonograph_edit2.jpg) | Levin C. Handy, c.1877 |
| `red-panda.jpg` | cc0 | CC0 1.0 | [Red Panda (24986761703)](https://commons.wikimedia.org/wiki/File:Red_Panda_(24986761703).jpg) | Mathias Appel, 2016 |
| `singer-ad.jpg` | pd | PD-old/1929 | [Singer_sewing_machines_poster_1892.jpg](https://commons.wikimedia.org/wiki/File:Singer_sewing_machines_poster_1892.jpg) | J. Ottmann Lith. Co., 1892 |
| `tabby-cat.jpg` | cc0 | CC0 1.0 | [Pixabay 3336579](https://commons.wikimedia.org/wiki/File:Tabby_cat_with_blue_eyes-3336579.jpg) | AdinaVoicu, 2018 |
| `tesla.jpg` | pd | PD-old | [Tesla_Sarony.jpg](https://commons.wikimedia.org/wiki/File:Tesla_Sarony.jpg) | Napoleon Sarony, c.1893 |
| `typewriter-ad.jpg` | pd | PD-old/1929 | [Underwood typewriter advertisement 1909](https://commons.wikimedia.org/wiki/File:PSM_V75_D640_Underwood_typewriter_advertisement_1909.jpg) | Popular Science Monthly, 1909 |
| `woman-singer.jpg` | cc0 | CC0 1.0 | [Parastoo Ahmadi](https://commons.wikimedia.org/wiki/File:Parastoo_Ahmadi.jpg) | Hosseinronaghi, 2024 |
| `wright-brothers.jpg` | pd | PD-old/1929 | [Wright_Brothers_in_1910.jpg](https://commons.wikimedia.org/wiki/File:Wright_Brothers_in_1910.jpg) | Unknown photographer, 1910 |
| `yoga.jpg` | own | CC BY 4.0 | Own work | Franz Enzenhofer |

## Lint

`scripts/lint-fixtures.sh` walks `Tests/fixtures/*.{jpg,png}` and the
table above. The build fails on:

- a file present in the directory but not in the table
- a row in the table without a matching file
- a row missing tier / licence / source

## Adding a fixture

1. Pick a content-descriptive kebab-case filename (`woman-in-library.jpg`,
   not `2024-06-photo-final.jpg`).
2. Place it in `Tests/fixtures/`.
3. Add a row above with tier, licence, source URL, attribution.
4. Run `make test`.
