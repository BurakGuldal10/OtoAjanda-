/// Türkiye'de yaygın araç markaları ve modelleri
const Map<String, List<String>> carBrandsModels = {
  'Alfa Romeo': ['147', '156', '159', 'Giulia', 'Giulietta', 'Stelvio', 'Tonale'],
  'Aston Martin': ['DB11', 'DBX', 'Vantage'],
  'Audi': ['A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8', 'TT', 'R8', 'e-tron', 'e-tron GT'],
  'BMW': ['1 Serisi', '2 Serisi', '3 Serisi', '4 Serisi', '5 Serisi', '7 Serisi', '8 Serisi', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'iX', 'i3', 'i4', 'i7', 'M3', 'M4', 'M5'],
  'Chevrolet': ['Aveo', 'Captiva', 'Cruze', 'Spark', 'Trax'],
  'Citroën': ['Berlingo', 'C1', 'C2', 'C3', 'C3 Aircross', 'C4', 'C5 X', 'Jumpy', 'C4 Picasso', 'SpaceTourer'],
  'Dacia': ['Duster', 'Logan', 'Sandero', 'Spring', 'Jogger'],
  'Ferrari': ['296', '488', 'F8', 'Roma', 'SF90'],
  'Fiat': ['500', '500X', 'Doblo', 'Egea', 'Fiorino', 'Linea', 'Punto', 'Tipo'],
  'Ford': ['EcoSport', 'Edge', 'Fiesta', 'Focus', 'Kuga', 'Mondeo', 'Mustang', 'Puma', 'Ranger', 'Transit', 'Connect'],
  'Honda': ['Accord', 'Civic', 'CR-V', 'HR-V', 'Jazz', 'ZR-V'],
  'Hyundai': ['Bayon', 'Elantra', 'i10', 'i20', 'i30', 'IONIQ 5', 'IONIQ 6', 'Kona', 'Santa Fe', 'Tucson'],
  'Isuzu': ['D-Max', 'D-Max V-Cross'],
  'Jaguar': ['E-Pace', 'F-Pace', 'F-Type', 'I-Pace', 'XE', 'XF'],
  'Jeep': ['Cherokee', 'Compass', 'Grand Cherokee', 'Renegade', 'Wrangler'],
  'Kia': ['Ceed', 'EV6', 'Niro', 'Picanto', 'Rio', 'Sorento', 'Sportage', 'Stonic', 'Xceed'],
  'Lamborghini': ['Huracan', 'Urus'],
  'Land Rover': ['Defender', 'Discovery', 'Freelander', 'Range Rover', 'Range Rover Evoque', 'Range Rover Sport', 'Range Rover Velar'],
  'Lexus': ['IS', 'NX', 'RX', 'UX'],
  'Maserati': ['Ghibli', 'Grecale', 'Levante', 'Quattroporte'],
  'Mazda': ['2', '3', '6', 'CX-3', 'CX-30', 'CX-5', 'CX-60', 'MX-5'],
  'Mercedes-Benz': ['A Serisi', 'B Serisi', 'C Serisi', 'E Serisi', 'S Serisi', 'CLA', 'CLS', 'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'AMG GT', 'EQA', 'EQB', 'EQC', 'EQE', 'EQS', 'Sprinter', 'Vito'],
  'Mini': ['Cabrio', 'Clubman', 'Countryman', 'Hatch', 'Paceman'],
  'Mitsubishi': ['ASX', 'Eclipse Cross', 'L200', 'Outlander', 'Pajero'],
  'Nissan': ['Juke', 'Leaf', 'Micra', 'Navara', 'Note', 'Qashqai', 'X-Trail'],
  'Opel': ['Astra', 'Corsa', 'Crossland', 'Grandland', 'Insignia', 'Mokka', 'Zafira'],
  'Peugeot': ['2008', '208', '3008', '308', '408', '508', '5008', 'Rifter', 'Traveller'],
  'Porsche': ['718 Boxster', '718 Cayman', '911', 'Cayenne', 'Macan', 'Panamera', 'Taycan'],
  'Renault': ['Arkana', 'Austral', 'Captur', 'Clio', 'Espace', 'Fluence', 'Kadjar', 'Kangoo', 'Megane', 'Symbol', 'Taliant', 'Talisman', 'Zoe'],
  'Rolls-Royce': ['Cullinan', 'Ghost', 'Phantom', 'Wraith'],
  'SEAT': ['Arona', 'Ateca', 'Ibiza', 'Leon', 'Tarraco'],
  'Skoda': ['Fabia', 'Kamiq', 'Karoq', 'Kodiaq', 'Octavia', 'Scala', 'Superb'],
  'Subaru': ['Forester', 'Impreza', 'Legacy', 'Outback', 'XV'],
  'Suzuki': ['Baleno', 'Ignis', 'Jimny', 'S-Cross', 'Swift', 'Vitara'],
  'Tesla': ['Model 3', 'Model S', 'Model X', 'Model Y', 'Cybertruck'],
  'Toyota': ['Auris', 'Avensis', 'Aygo', 'C-HR', 'Camry', 'Corolla', 'Hilux', 'Land Cruiser', 'Proace', 'RAV4', 'Supra', 'Yaris', 'bZ4X'],
  'Volkswagen': ['Arteon', 'Golf', 'ID.3', 'ID.4', 'Passat', 'Polo', 'T-Cross', 'T-Roc', 'Taigo', 'Tiguan', 'Touareg', 'Touran', 'Up'],
  'Volvo': ['C40', 'S60', 'S90', 'V40', 'V60', 'V90', 'XC40', 'XC60', 'XC90'],
};

/// Sıralı marka listesi
List<String> get carBrandsList =>
    carBrandsModels.keys.toList()..sort();

/// Markaya göre model listesi
List<String> modelsForBrand(String brand) =>
    carBrandsModels[brand] ?? [];
