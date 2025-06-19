import 'package:flutter/material.dart';
import 'request_test_drive_screen.dart';
import 'search_screen.dart';

class ShowroomsScreen extends StatefulWidget {
  const ShowroomsScreen({super.key});

  @override
  State<ShowroomsScreen> createState() => _ShowroomsScreenState();
}

class _ShowroomsScreenState extends State<ShowroomsScreen> {
  // Sample showroom data
  final List<Map<String, dynamic>> _allShowrooms = [
    {
      'name': 'Tata Motors',
      'location': 'Andheri East, Mumbai',
      'rating': '4.5',
      'distance': '2.3 km',
      'cars': ['Tata Nexon EV', 'Tata Punch', 'Tata Harrier'],
      'phone': '+91 98765 43210',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Mahindra Auto',
      'location': 'Powai, Mumbai',
      'rating': '4.3',
      'distance': '4.1 km',
      'cars': ['Mahindra XUV700', 'Mahindra Thar', 'Mahindra Scorpio'],
      'phone': '+91 98765 43211',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Hyundai Motors',
      'location': 'Vikhroli, Mumbai',
      'rating': '4.7',
      'distance': '3.2 km',
      'cars': ['Hyundai Creta', 'Hyundai Venue', 'Hyundai i20'],
      'phone': '+91 98765 43212',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Maruti Suzuki',
      'location': 'Ghatkopar, Mumbai',
      'rating': '4.2',
      'distance': '5.8 km',
      'cars': ['Maruti Suzuki Baleno', 'Maruti Swift', 'Maruti Brezza'],
      'phone': '+91 98765 43213',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Kia Motors',
      'location': 'Bhandup, Mumbai',
      'rating': '4.6',
      'distance': '6.5 km',
      'cars': ['Kia Seltos', 'Kia Sonet', 'Kia Carens'],
      'phone': '+91 98765 43214',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Honda Cars',
      'location': 'Kandivali, Mumbai',
      'rating': '4.4',
      'distance': '7.2 km',
      'cars': ['Honda City', 'Honda Amaze', 'Honda WR-V'],
      'phone': '+91 98765 43215',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'Toyota Motors',
      'location': 'Borivali, Mumbai',
      'rating': '4.8',
      'distance': '8.1 km',
      'cars': ['Toyota Innova', 'Toyota Fortuner', 'Toyota Camry'],
      'phone': '+91 98765 43216',
      'image': 'assets/images/varenium.png',
    },
    {
      'name': 'MG Motors',
      'location': 'Thane, Mumbai',
      'rating': '4.1',
      'distance': '9.3 km',
      'cars': ['MG Hector', 'MG ZS EV', 'MG Astor'],
      'phone': '+91 98765 43217',
      'image': 'assets/images/varenium.png',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Showrooms',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search showrooms or locations...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.mic_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Showrooms Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _allShowrooms.length,
              itemBuilder: (context, index) {
                final showroom = _allShowrooms[index];
                return _buildShowroomCard(showroom);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowroomCard(Map<String, dynamic> showroom) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestTestDriveScreen(
                showroomName: showroom['name'],
                availableCars: List<String>.from(showroom['cars']),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0095D9).withOpacity(0.1),
                    const Color(0xFF0095D9).withOpacity(0.05),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095D9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            showroom['rating'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showroom['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            showroom['location'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 11,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${showroom['cars'].length} cars',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          showroom['distance'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestTestDriveScreen(
                                showroomName: showroom['name'],
                                availableCars: List<String>.from(showroom['cars']),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Book Drive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 