/// Represents a government department or office
class GovernmentDepartment {
  const GovernmentDepartment({
    required this.name,
    this.directorName,
    this.phone,
    this.email,
    this.address,
    this.fax,
    this.officeHours,
    this.description,
  });

  final String name;
  final String? directorName;
  final String? phone;
  final String? email;
  final String? address;
  final String? fax;
  final String? officeHours;
  final String? description;
}

/// Represents a government official
class GovernmentOfficial {
  const GovernmentOfficial({
    required this.name,
    required this.position,
    this.phone,
    this.email,
    this.cellPhone,
    this.address,
  });

  final String name;
  final String position;
  final String? phone;
  final String? email;
  final String? cellPhone;
  final String? address;
}

/// Represents a government entity (county, city, town)
class GovernmentEntity {
  const GovernmentEntity({
    required this.name,
    required this.type, // 'County', 'City', 'Town'
    this.mainAddress,
    this.mainPhone,
    this.mainEmail,
    this.website,
    this.departments = const [],
    this.officials = const [],
    this.locations = const [],
  });

  final String name;
  final String type;
  final String? mainAddress;
  final String? mainPhone;
  final String? mainEmail;
  final String? website;
  final List<GovernmentDepartment> departments;
  final List<GovernmentOfficial> officials;
  final List<String> locations; // Additional office locations
}

/// Hard-coded government information for Putnam County entities
class GovernmentData {
  static const GovernmentEntity putnamCounty = GovernmentEntity(
    name: 'Putnam County',
    type: 'County',
    mainAddress: '2509 Crill Ave., Ste. 200, Palatka, FL 32177',
    mainPhone: '(386) 329-0200',
    mainEmail: 'info@putnam-fl.gov',
    website: 'https://www.putnam-fl.gov',
    departments: [
      GovernmentDepartment(
        name: 'County Administrator',
        directorName: 'Terry Suggs',
        phone: '(386) 329-0207',
        email: 'terry.suggs@putnam-fl.gov',
        address: '2509 Crill Ave., Ste. 200, Palatka, FL 32177',
        fax: '(386) 329-1216',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'County Attorney',
        directorName: 'Rich Komando',
        phone: '(386) 329-0392',
        email: 'rich@claylawyers.com',
        address: '2509 Crill Ave., Ste. 200, Palatka, FL 32177',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Public Works',
        directorName: 'James "JT" Stout',
        phone: '(386) 329-0346',
        email: 'publicworks@putnam-fl.gov',
        address: '223 Putnam County Blvd., East Palatka, FL 32131',
        fax: '(386) 329-0340',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Emergency Management',
        directorName: 'Steffen Turnipseed',
        phone: '(386) 326-2793',
        email: 'steffen.turnipseed@putnam-fl.gov',
        address: '410 S. State Road 19, Palatka, FL 32177',
        fax: '(386) 329-0897',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Information Technology',
        directorName: 'James Richie',
        phone: '(386) 329-0216',
        email: 'james.richie@putnam-fl.gov',
        address: '105 S. 4th St., 2nd Floor, Palatka, FL 32177',
        fax: '(386) 329-0215',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'General Services',
        directorName: 'Julianne Young',
        phone: '(386) 329-0370',
        email: 'julianne.young@putnam-fl.gov',
        address: '2509 Crill Ave., Suite 200, Palatka, FL 32177',
        fax: '(386) 329-1216',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Human Resources',
        directorName: 'Laurie Parker',
        phone: '(386) 329-0221',
        email: 'laurie.parker@putnam-fl.gov',
        address: '2509 Crill Ave., Palatka, FL 32177',
        fax: '(386) 329-1257',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Procurement',
        directorName: 'Leigh Doran',
        phone: '(386) 329-0376',
        email: 'leigh.doran@putnam-fl.gov',
        address: '2509 Crill Ave., Palatka, FL 32177',
        fax: '(386) 329-0468',
        officeHours: 'Monday - Friday, 8:30am - 5:00pm',
      ),
      GovernmentDepartment(
        name: 'Florida Department of Health in Putnam County',
        phone: '(386) 326-3200',
        email: 'chd54webmaster@flhealth.gov',
        address: '2801 Kennedy Street, Palatka, FL 32177',
        fax: '(386) 326-3350',
        officeHours: 'Monday - Friday, 8:00am - 5:00pm',
      ),
    ],
    officials: [
      GovernmentOfficial(
        name: 'JR Newbold',
        position: 'County Commissioner - District 1',
        email: 'jr.newbold@putnam-fl.com',
        phone: '(386) 329-0200',
      ),
      GovernmentOfficial(
        name: 'Leota Wilkinson',
        position: 'County Commissioner - District 2 (Chair)',
        email: 'leota.wilkinson@putnam-fl.gov',
        phone: '(386) 329-0212',
      ),
      GovernmentOfficial(
        name: 'Josh Alexander',
        position: 'County Commissioner - District 3',
        email: 'josh.alexander@putnam-fl.com',
        phone: '(386) 329-0200',
      ),
      GovernmentOfficial(
        name: 'Larry Harvey',
        position: 'County Commissioner - District 4 (Vice-Chair)',
        email: 'larry.harvey@putnam-fl.gov',
        phone: '(386) 329-0213',
        cellPhone: '(386) 916-8923',
      ),
      GovernmentOfficial(
        name: 'Walton Pellicer',
        position: 'County Commissioner - District 5',
        email: 'walton.pellicer@putnam-fl.com',
        phone: '(386) 329-0200',
      ),
      GovernmentOfficial(
        name: 'Matt Reynolds',
        position: 'Clerk of the Circuit Court',
        email: 'matt.reynolds@putnam-fl.com',
        phone: '(386) 326-7600',
        address: '410 St. Johns Ave., Palatka, FL 32177',
      ),
      GovernmentOfficial(
        name: 'H.D. "Gator" DeLoach III',
        position: 'Sheriff',
        email: 'hdeloach@putnamsheriff.org',
        phone: '(386) 329-0800',
        address: '130 Orie Griffin Blvd., Palatka, FL 32177',
      ),
      GovernmentOfficial(
        name: 'Linda Myers',
        position: 'Tax Collector',
        email: 'linda.myers@putnam-fl.gov',
        phone: '(386) 329-0282',
        address: 'P.O. Drawer 1339, Palatka, FL 32178-1339',
      ),
      GovernmentOfficial(
        name: 'Charles Overturf',
        position: 'Supervisor of Elections',
        email: 'charles.overturf@putnam-fl.gov',
        phone: '(386) 329-0224',
        address: '107 N. Sixth St., Palatka, FL 32177',
      ),
      GovernmentOfficial(
        name: 'Tim Parker',
        position: 'Property Appraiser',
        email: 'tim.parker@putnam-fl.gov',
        phone: '(386) 329-0286',
        address: 'P.O. Box 1920, Palatka, FL 32178-1920',
      ),
    ],
    locations: [
      'Driver License & Motor Vehicle - Crescent City: 115 N. Summit St., Crescent City, FL 32112, (386) 329-0282',
      'Driver License & Motor Vehicle - Interlachen: 1114 State Road 20 W., Suite #5, Interlachen, FL 32148, (386) 329-0282',
      'Driver License & Motor Vehicle - Palatka: 312 Oak St., Palatka, FL 32177, (386) 329-0282',
    ],
  );

  static const GovernmentEntity palatka = GovernmentEntity(
    name: 'Palatka',
    type: 'City',
    mainAddress: 'City Hall, Palatka, FL 32177',
    mainPhone: '(386) 329-0100',
    departments: [],
    officials: [],
    locations: [],
  );

  static const GovernmentEntity crescentCity = GovernmentEntity(
    name: 'Crescent City',
    type: 'City',
    mainAddress: 'City Hall, Crescent City, FL 32112',
    mainPhone: '(386) 698-2525',
    departments: [],
    officials: [],
    locations: [],
  );

  static const GovernmentEntity interlachen = GovernmentEntity(
    name: 'Interlachen',
    type: 'Town',
    mainAddress: 'Town Hall, Interlachen, FL 32148',
    mainPhone: '(386) 684-3444',
    departments: [],
    officials: [],
    locations: [],
  );

  static const GovernmentEntity welaka = GovernmentEntity(
    name: 'Welaka',
    type: 'Town',
    mainAddress: 'Town Hall, Welaka, FL 32193',
    mainPhone: '(386) 467-2477',
    departments: [],
    officials: [],
    locations: [],
  );

  /// Get government entity by name
  static GovernmentEntity? getByName(String name) {
    switch (name.toLowerCase()) {
      case 'putnam county':
        return putnamCounty;
      case 'palatka':
        return palatka;
      case 'crescent city':
        return crescentCity;
      case 'interlachen':
        return interlachen;
      case 'welaka':
        return welaka;
      default:
        return null;
    }
  }
}

