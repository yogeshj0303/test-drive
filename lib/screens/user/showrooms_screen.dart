// import 'package:flutter/material.dart';
// import 'cars_screen.dart';
// import 'search_screen.dart';
// import '../../services/api_service.dart';
// import '../../services/api_config.dart';
// import '../../services/storage_service.dart';
// import '../../models/showroom_model.dart';
// import '../../models/user_model.dart';

// class ShowroomsScreen extends StatefulWidget {
//   const ShowroomsScreen({super.key});

//   @override
//   State<ShowroomsScreen> createState() => _ShowroomsScreenState();
// }

// class _ShowroomsScreenState extends State<ShowroomsScreen> {
//   final ApiService _apiService = ApiService();
//   final StorageService _storageService = StorageService();
//   List<Showroom> _showrooms = [];
//   List<Showroom> _filteredShowrooms = [];
//   Map<int, int> _carCounts = {}; // Store car counts for each showroom
//   bool _isLoading = true;
//   String? _errorMessage;
//   User? _currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _fetchShowrooms();
//   }

//   void _applyFilter(String filterType) async {
//     // Since we're only showing the user's assigned showroom, 
//     // all filters will show the same showroom
//     setState(() {
//       _filteredShowrooms = List.from(_showrooms);
//       _errorMessage = null; // Clear previous errors
//     });
    
//     // Show a message that this is the user's assigned showroom
//     if (mounted && _showrooms.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Showing your assigned showroom: ${_showrooms.first.name}'),
//           duration: const Duration(seconds: 2),
//           backgroundColor: const Color(0xFF0095D9),
//         ),
//       );
//     }
//   }

//   Future<void> _fetchCarCountsForShowrooms(List<Showroom> showrooms) async {
//     for (final showroom in showrooms) {
//       try {
//         final carResponse = await _apiService.getCarsByShowroom(showroom.id);
//         if (carResponse.success) {
//           setState(() {
//             _carCounts[showroom.id] = carResponse.data?.length ?? 0;
//           });
//         }
//       } catch (e) {
//         // If car count fetch fails, set to 0
//         setState(() {
//           _carCounts[showroom.id] = 0;
//         });
//       }
//     }
//   }

//   Future<void> _fetchShowrooms() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       // Get current user to check their showroom_id
//       _currentUser = await _storageService.getUser();
//       if (_currentUser == null) {
//         setState(() {
//           _errorMessage = 'User not found. Please login again.';
//           _isLoading = false;
//         });
//         return;
//       }

//       final response = await _apiService.getShowrooms();
      
//       if (response.success) {
//         // Filter showrooms to only show the one that matches user's showroom_id
//         final allShowrooms = response.data ?? [];
//         final filteredShowrooms = allShowrooms.where((showroom) => 
//           showroom.id == _currentUser!.showroomId
//         ).toList();
        
//         setState(() {
//           _showrooms = filteredShowrooms;
//           _filteredShowrooms = List.from(filteredShowrooms);
//           _isLoading = false;
//         });
        
//         // Fetch car counts for each showroom
//         _fetchCarCountsForShowrooms(_showrooms);
//       } else {
//         setState(() {
//           _errorMessage = response.message;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'An unexpected error occurred';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'My Showroom',
//           style: TextStyle(
//             color: Color(0xFF1A1A1A),
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           if (!_isLoading)
//             IconButton(
//               icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A1A)),
//               onPressed: _fetchShowrooms,
//             ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             height: 1,
//             color: Colors.grey[200],
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Container(
//               height: 52,
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: Colors.grey[200]!,
//                   width: 1,
//                 ),
//               ),
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const SearchScreen(),
//                       ),
//                     );
//                   },
//                   borderRadius: BorderRadius.circular(16),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.search_rounded,
//                           color: Colors.grey[600],
//                           size: 22,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             'Search cars in your showroom...',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 15,
//                               fontWeight: FontWeight.w400,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         Container(
//                           height: 24,
//                           width: 1,
//                           color: Colors.grey[200],
//                         ),
//                         const SizedBox(width: 12),
//                         Icon(
//                           Icons.mic_rounded,
//                           color: Colors.grey[600],
//                           size: 22,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // Filter Section
//           if (!_isLoading && _showrooms.isNotEmpty)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF0095D9),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Center(
//                         child: Text(
//                           'My Showroom',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           // Content
//           Expanded(
//             child: _buildContent(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (_isLoading) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Loading showrooms...',
//               style: TextStyle(
//                 color: Color(0xFF666666),
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline_rounded,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _errorMessage!,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _fetchShowrooms,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF0095D9),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_filteredShowrooms.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.store_outlined,
//               size: 64,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'No showroom assigned',
//               style: TextStyle(
//                 color: Color(0xFF666666),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Please contact your administrator to assign a showroom',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//       ),
//       itemCount: _filteredShowrooms.length,
//       itemBuilder: (context, index) {
//         final showroom = _filteredShowrooms[index];
//         return _buildShowroomCard(showroom);
//       },
//     );
//   }

//   Widget _buildShowroomCard(Showroom showroom) {
//     return Card(
//       elevation: 4,
//       shadowColor: Colors.black.withOpacity(0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => CarsScreen(
//                 showroomName: showroom.name,
//                 availableCars: [], // Will be populated when cars API is available
//                 showroomLocation: showroom.locationDisplay,
//                 showroomRating: showroom.ratting.toString(), // Use actual rating from API
//                 showroomDistance: 'N/A', // Will be calculated based on user location
//                 showroomId: showroom.id,
//               ),
//             ),
//           );
//         },
//         borderRadius: BorderRadius.circular(20),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Colors.white,
//                 Colors.grey[50]!,
//               ],
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header section with image and rating
//               Container(
//                 height: 120,
//                 decoration: BoxDecoration(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     // Showroom image
//                     ClipRRect(
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(20),
//                         topRight: Radius.circular(20),
//                       ),
//                       child: showroom.showroomImage != null
//                           ? Image.network(
//                               '${ApiConfig.baseUrl}/${showroom.showroomImage!}',
//                               width: double.infinity,
//                               height: 120,
//                               fit: BoxFit.fill,
//                               alignment: Alignment.center,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Container(
//                                   width: double.infinity,
//                                   height: 120,
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                       colors: [
//                                         const Color(0xFF0095D9).withOpacity(0.15),
//                                         const Color(0xFF0095D9).withOpacity(0.08),
//                                       ],
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: Container(
//                                       width: 45,
//                                       height: 45,
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFF0095D9).withOpacity(0.1),
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       child: const Icon(
//                                         Icons.store_rounded,
//                                         color: Color(0xFF0095D9),
//                                         size: 24,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               loadingBuilder: (context, child, loadingProgress) {
//                                 if (loadingProgress == null) return child;
//                                 return Container(
//                                   width: double.infinity,
//                                   height: 120,
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                       colors: [
//                                         const Color(0xFF0095D9).withOpacity(0.15),
//                                         const Color(0xFF0095D9).withOpacity(0.08),
//                                       ],
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: CircularProgressIndicator(
//                                       value: loadingProgress.expectedTotalBytes != null
//                                           ? loadingProgress.cumulativeBytesLoaded /
//                                               loadingProgress.expectedTotalBytes!
//                                           : null,
//                                       valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
//                                       strokeWidth: 2,
//                                     ),
//                                   ),
//                                 );
//                               },
//                             )
//                           : Container(
//                               width: double.infinity,
//                               height: 100,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                   colors: [
//                                     const Color(0xFF0095D9).withOpacity(0.15),
//                                     const Color(0xFF0095D9).withOpacity(0.08),
//                                   ],
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Container(
//                                   width: 45,
//                                   height: 45,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF0095D9).withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: const Icon(
//                                     Icons.store_rounded,
//                                     color: Color(0xFF0095D9),
//                                     size: 24,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                     ),
//                     // Rating badge
//                     Positioned(
//                       top: 10,
//                       right: 10,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 3,
//                               offset: const Offset(0, 1),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(
//                               Icons.star_rounded,
//                               color: Color(0xFFFFD700),
//                               size: 11,
//                             ),
//                             const SizedBox(width: 2),
//                             Text(
//                               showroom.ratting.toString(), // Use actual rating from API
//                               style: TextStyle(
//                                 color: Colors.grey[800],
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Content section
//               Flexible(
//                 child: Padding(
//                   padding: const EdgeInsets.all(10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Showroom name
//                       Flexible(
//                         child: Text(
//                           showroom.name,
//                           style: const TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF1A1A1A),
//                             height: 1.2,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // Location
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(3),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Icon(
//                               Icons.location_on_rounded,
//                               size: 10,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               showroom.locationDisplay,
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.grey[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 3),
//                       // Available cars
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(3),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Icon(
//                               Icons.directions_car_rounded,
//                               size: 10,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               'Available cars',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.grey[700],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF0095D9).withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                             child: Text(
//                               _carCounts[showroom.id]?.toString() ?? 'N/A',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 color: const Color(0xFF0095D9),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       // Book Drive button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 26,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => CarsScreen(
//                                   showroomName: showroom.name,
//                                   availableCars: [], // Will be populated when cars API is available
//                                   showroomLocation: showroom.locationDisplay,
//                                   showroomRating: showroom.ratting.toString(), // Use actual rating from API
//                                   showroomDistance: 'N/A', // Will be calculated based on user location
//                                   showroomId: showroom.id,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF0095D9),
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shadowColor: Colors.transparent,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: const Text(
//                             'Book Drive',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// } 