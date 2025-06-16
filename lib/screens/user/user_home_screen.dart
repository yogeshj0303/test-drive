import 'package:flutter/material.dart';
import 'request_test_drive_screen.dart';
import 'test_drive_status_screen.dart';
import 'review_form_screen.dart';
import 'notification_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> featuredCars = [
    {
      'name': 'Tata Nexon EV',
      'price': '₹14.99 L',
      'power': '129 PS',
      'range': '437 km',
      'transmission': 'Auto',
      'showroom': 'Tata Motors, Andheri East',
    },
    {
      'name': 'Mahindra XUV700',
      'price': '₹13.45 L',
      'power': '200 PS',
      'range': '450 km',
      'transmission': 'Auto',
      'showroom': 'Mahindra Auto, Powai',
    },
    {
      'name': 'Hyundai Creta',
      'price': '₹10.99 L',
      'power': '115 PS',
      'range': '400 km',
      'transmission': 'Auto',
      'showroom': 'Hyundai Motors, Vikhroli',
    },
    {
      'name': 'Maruti Suzuki Baleno',
      'price': '₹6.49 L',
      'power': '90 PS',
      'range': '380 km',
      'transmission': 'Manual',
      'showroom': 'Maruti Suzuki, Ghatkopar',
    },
    {
      'name': 'Kia Seltos',
      'price': '₹10.89 L',
      'power': '115 PS',
      'range': '410 km',
      'transmission': 'Auto',
      'showroom': 'Kia Motors, Bhandup',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Varenium',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          _buildTopBarIcon(
            Icons.notifications_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildTopBarIcon(
            Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                      // TODO: Handle search tap
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
                              'Search cars, brands, or models...',
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
            // Quick Filters
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('All Cars', _selectedFilterIndex == 0, Icons.directions_car_rounded),
                  _buildFilterChip('Electric', _selectedFilterIndex == 1, Icons.electric_car_rounded),
                  _buildFilterChip('SUV', _selectedFilterIndex == 2, Icons.directions_car_filled_rounded),
                  _buildFilterChip('Sedan', _selectedFilterIndex == 3, Icons.directions_car_outlined),
                  _buildFilterChip('Hatchback', _selectedFilterIndex == 4, Icons.directions_car_rounded),
                  _buildFilterChip('Luxury', _selectedFilterIndex == 5, Icons.star_rounded),
                ],
              ),
            ),
            // Featured Cars Section
            _buildSectionHeader(
              'Featured Cars',
              'Explore our premium selection of vehicles',
              onViewAll: () {
                // TODO: Implement view all functionality
              },
            ),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featuredCars.length,
                itemBuilder: (context, index) {
                  final car = featuredCars[index];
                  return _buildFeaturedCarCard(car);
                },
              ),
            ),
            // Quick Actions Section
            _buildSectionHeader(
              'Quick Actions',
              'Manage your test drive requests and reviews',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final actions = [
                    {
                      'title': 'Schedule Test Drive',
                      'icon': Icons.directions_car_rounded,
                      'color': Colors.orange,
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RequestTestDriveScreen(),
                          ),
                        );
                      },
                    },
                    {
                      'title': 'View Status',
                      'icon': Icons.update_rounded,
                      'color': Colors.green,
                      'onTap': () {
                        // TODO: Navigate to status screen
                      },
                    },
                    {
                      'title': 'Cancel Test Drive',
                      'icon': Icons.cancel_outlined,
                      'color': Colors.red,
                      'onTap': () {
                        _showCancellationDialog();
                      },
                    },
                    {
                      'title': 'Write Review',
                      'icon': Icons.rate_review_rounded,
                      'color': Colors.purple,
                      'onTap': () {
                        // TODO: Navigate to review screen
                      },
                    },
                  ];
                  final action = actions[index];
                  return SizedBox(
                    height: 100,
                    child: _buildActionCard(
                      action['title'] as String,
                      action['icon'] as IconData,
                      action['color'] as Color,
                      action['onTap'] as VoidCallback,
                    ),
                  );
                },
              ),
            ),
            // Promotional Banners Section
            _buildSectionHeader(
              'Special Offers',
              'Exclusive deals and promotions for you',
            ),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPromoBanner(
                    'Summer Special',
                    'Get up to ₹50,000 off on select models',
                    Icons.local_offer_rounded,
                    const Color(0xFFFF6B6B),
                  ),
                  _buildPromoBanner(
                    'Electric Vehicle Bonus',
                    'Additional ₹25,000 off on all EVs',
                    Icons.electric_car_rounded,
                    const Color(0xFF4CAF50),
                  ),
                  _buildPromoBanner(
                    'Weekend Test Drive',
                    'Book a test drive this weekend for special benefits',
                    Icons.weekend_rounded,
                    const Color(0xFF2196F3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle,
      {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095D9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onViewAll != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0095D9).withOpacity(0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: const Color(0xFF0095D9).withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, IconData icon) {
    final theme = Theme.of(context);
    final index = _getFilterIndex(label);
    final isCurrentlySelected = index == _selectedFilterIndex;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentlySelected 
                  ? theme.primaryColor.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isCurrentlySelected 
                    ? theme.primaryColor.withOpacity(0.3)
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isCurrentlySelected 
                      ? theme.primaryColor 
                      : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isCurrentlySelected 
                        ? theme.primaryColor 
                        : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: isCurrentlySelected 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getFilterIndex(String label) {
    switch (label) {
      case 'All Cars':
        return 0;
      case 'Electric':
        return 1;
      case 'SUV':
        return 2;
      case 'Sedan':
        return 3;
      case 'Hatchback':
        return 4;
      case 'Luxury':
        return 5;
      default:
        return 0;
    }
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: const Color(0xFF0095D9),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF757575),
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFeaturedCarCard(Map<String, dynamic> car) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 272,
          height: 230,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top image section
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          car['price'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car name
                      Text(
                        car['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Showroom location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF0095D9),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              car['showroom'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Specs row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 80,
                            child: _buildSpecItem('Power', car['power'], Icons.speed),
                          ),
                          SizedBox(
                            width: 80,
                            child: _buildSpecItem('Range', car['range'], Icons.route),
                          ),
                          SizedBox(
                            width: 80,
                            child: _buildSpecItem('Trans', car['transmission'], Icons.settings),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Book button
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RequestTestDriveScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0095D9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Test Drive',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
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
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Test Drive',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can cancel your test drive up to 1 hour before the scheduled time.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to proceed with cancellation?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep It',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cancellation logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle banner tap
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 22,
          ),
        ),
      ),
    );
  }
}
