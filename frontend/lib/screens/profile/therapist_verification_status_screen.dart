import 'package:flutter/material.dart';

import '../therapist/therapist_dashboard_screen.dart';
import 'join_therapist_screen.dart';

class TherapistVerificationStatus extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String verificationStatus;
  final String? rejectionReason;
  final String userId;
  
  const TherapistVerificationStatus({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userId,
    this.verificationStatus = 'pending',
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Application Status',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 375,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    verificationStatus == 'approved' 
                      ? Icons.check_circle 
                      : verificationStatus == 'rejected'
                        ? Icons.cancel
                        : Icons.schedule,
                    color: verificationStatus == 'approved'
                      ? const Color.fromRGBO(34, 197, 94, 1)
                      : verificationStatus == 'rejected'
                        ? const Color.fromRGBO(220, 38, 38, 1)
                        : const Color.fromRGBO(249, 115, 22, 1),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  verificationStatus == 'approved'
                    ? 'Application Approved!'
                    : verificationStatus == 'rejected'
                      ? 'Application Rejected'
                      : 'Application Submitted!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Status Message
                Text(
                  verificationStatus == 'approved'
                    ? 'Congratulations! Your therapist application has been approved. You can now start offering your services on the platform.'
                    : verificationStatus == 'rejected'
                      ? 'Unfortunately, your application has been rejected. Please review the reason below and feel free to reapply after addressing the concerns.'
                      : 'Thank you for submitting your therapist application. We have received your information and will review it shortly.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(107, 114, 128, 1),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Name', '$firstName $lastName'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Email', email),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Status', 
                        verificationStatus == 'approved' ? 'Approved' : verificationStatus == 'rejected' ? 'Rejected' : 'Pending',
                        isPending: verificationStatus == 'pending',
                        isApproved: verificationStatus == 'approved',
                        isRejected: verificationStatus == 'rejected',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Rejection Reason Card (only show if rejected)
                if (verificationStatus == 'rejected' && rejectionReason != null && rejectionReason!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 226, 226, 1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(220, 38, 38, 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color.fromRGBO(220, 38, 38, 1),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rejection Reason',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(127, 29, 29, 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rejectionReason!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(127, 29, 29, 1),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: verificationStatus == 'approved'
                      ? const Color.fromRGBO(220, 252, 231, 1)
                      : verificationStatus == 'rejected'
                        ? const Color.fromRGBO(254, 226, 226, 1)
                        : const Color.fromRGBO(254, 243, 199, 1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: verificationStatus == 'approved'
                        ? const Color.fromRGBO(34, 197, 94, 0.3)
                        : verificationStatus == 'rejected'
                          ? const Color.fromRGBO(220, 38, 38, 0.3)
                          : const Color.fromRGBO(249, 115, 22, 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: verificationStatus == 'approved'
                            ? const Color.fromRGBO(34, 197, 94, 1)
                            : verificationStatus == 'rejected'
                              ? const Color.fromRGBO(220, 38, 38, 1)
                              : const Color.fromRGBO(249, 115, 22, 1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        verificationStatus == 'approved'
                          ? 'Verified Therapist'
                          : verificationStatus == 'rejected'
                            ? 'Application Rejected'
                            : 'Verification Pending',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          color: verificationStatus == 'approved'
                            ? const Color.fromRGBO(21, 128, 61, 1)
                            : verificationStatus == 'rejected'
                              ? const Color.fromRGBO(127, 29, 29, 1)
                              : const Color.fromRGBO(146, 64, 14, 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons based on status
                if (verificationStatus == 'approved')
                  // Go to Therapist Dashboard Button for approved
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(34, 197, 94, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TherapistDashboardScreen(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Go to Therapist Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (verificationStatus == 'rejected')
                  // Resubmit Button for rejected
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JoinTherapist(
                                  userId: userId,
                                  isResubmission: true,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Resubmit Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Color.fromRGBO(66, 32, 6, 1),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(66, 32, 6, 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Back to Profile for pending
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPending = false, bool isApproved = false, bool isRejected = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            color: Color.fromRGBO(107, 114, 128, 1),
          ),
        ),
        (isPending || isApproved || isRejected)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                    ? const Color.fromRGBO(220, 252, 231, 1)
                    : isRejected
                      ? const Color.fromRGBO(254, 226, 226, 1)
                      : const Color.fromRGBO(254, 243, 199, 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: isApproved
                      ? const Color.fromRGBO(21, 128, 61, 1)
                      : isRejected
                        ? const Color.fromRGBO(127, 29, 29, 1)
                        : const Color.fromRGBO(146, 64, 14, 1),
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(66, 32, 6, 1),
                ),
              ),
      ],
    );
  }
}
