import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3080A5);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildAppInfoCard(primaryBlue),
              const SizedBox(height: 24),
              _buildSectionHeader('App Information', primaryBlue),
              const SizedBox(height: 12),
              _buildInfoSection(primaryBlue),
              const SizedBox(height: 24),
              _buildSectionHeader('Company Information', primaryBlue),
              const SizedBox(height: 12),
              _buildCompanySection(primaryBlue),
              const SizedBox(height: 24),
              _buildSectionHeader('Support & Contact', primaryBlue),
              const SizedBox(height: 12),
              _buildSupportSection(primaryBlue),
              const SizedBox(height: 32),
              _buildLegalSection(primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue,
                  primaryBlue.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Varenyam',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test Drive Management System',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryBlue) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            'App Version',
            '1.0.0',
            Icons.info_outline_rounded,
            primaryBlue,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Build Number',
            '2024.1.0',
            Icons.build_rounded,
            Colors.orange,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Last Updated',
            'January 2024',
            Icons.update_rounded,
            Colors.green,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Platform',
            'Flutter',
            Icons.mobile_friendly_rounded,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            'Company',
            'Varenyam Motors',
            Icons.business_rounded,
            primaryBlue,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Website',
            'www.Varenyam.com',
            Icons.language_rounded,
            Colors.blue,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Email',
            'info@Varenyam.com',
            Icons.email_rounded,
            Colors.green,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Phone',
            '+91 1800-123-4567',
            Icons.phone_rounded,
            Colors.orange,
            isClickable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            'Support Email',
            'support@Varenyam.com',
            Icons.support_agent_rounded,
            Colors.red,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Help Center',
            'help.Varenyam.com',
            Icons.help_rounded,
            Colors.blue,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Feedback',
            'Send us feedback',
            Icons.feedback_rounded,
            Colors.purple,
            isClickable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            'Privacy Policy',
            'View privacy policy',
            Icons.privacy_tip_rounded,
            Colors.grey,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Terms of Service',
            'View terms of service',
            Icons.description_rounded,
            Colors.grey,
            isClickable: true,
          ),
          _buildDivider(),
          _buildInfoItem(
            'Licenses',
            'View open source licenses',
            Icons.description_outlined,
            Colors.grey,
            isClickable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon, Color color, {bool isClickable = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isClickable ? () => _handleItemTap(title, value) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 56,
    );
  }

  void _handleItemTap(String title, String value) {
    // Handle different item taps
    switch (title) {
      case 'Website':
        // Open website
        break;
      case 'Email':
        // Open email app
        break;
      case 'Phone':
        // Open phone app
        break;
      case 'Support Email':
        // Open email app
        break;
      case 'Help Center':
        // Open help center
        break;
      case 'Feedback':
        // Open feedback form
        break;
      case 'Privacy Policy':
        // Open privacy policy
        break;
      case 'Terms of Service':
        // Open terms of service
        break;
      case 'Licenses':
        // Open licenses
        break;
    }
  }
} 