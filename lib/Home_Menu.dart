import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model untuk data anggota
class Member {
  final String fullName;
  final String nimNip;
  final String status;
  final String? avatarUrl; // Menggunakan 'avatar_url' sesuai nama kolom di DB

  Member({
    required this.fullName,
    required this.nimNip,
    required this.status,
    this.avatarUrl, // Sesuaikan di constructor
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      fullName: json['full_name'] ?? '',
      nimNip: json['nim_nip'] ?? '',
      status: json['status'] ?? '',
      avatarUrl:
          json['avatar_url'], // Mengambil dari JSON dengan nama kolom yang benar
    );
  }
}

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  _TabHomeState createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> {
  late Future<List<Member>> _membersFuture;
  TextEditingController _searchController = TextEditingController();
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _membersFuture = fetchMembers();
  }

  // Fungsi untuk memuat ulang data anggota
  Future<void> _refreshMembers() async {
    setState(() {
      _membersFuture = fetchMembers(); // Memuat ulang future
    });
  }

  Future<List<Member>> fetchMembers() async {
    try {
      print('[DEBUG] Fetching members from Supabase...');
      final response = await Supabase.instance.client
          .from('profiles') // Nama tabel di Supabase
          .select(
            'full_name, nim_nip, status, avatar_url',
          ); // Mengambil 'avatar_url' dari DB

      print('[DEBUG] Supabase raw response type: ${response.runtimeType}');
      print('[DEBUG] Supabase raw response: $response');

      if (response.isEmpty) {
        print('[DEBUG] Supabase returned an empty list of data.');
      } else {
        print(
          '[DEBUG] Supabase returned ${response.length} items. First item: ${response.first}',
        );
      }

      final List<Member> members =
          response.map((json) => Member.fromJson(json)).toList();

      print('[DEBUG] Converted members list count: ${members.length}');

      _allMembers = members;
      _filteredMembers = members;
      return members;
    } on PostgrestException catch (e) {
      print('--- Supabase PostgrestException ---');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.details}');
      print('Hint: ${e.hint}');
      print('-----------------------------------');
      return [];
    } catch (e) {
      print('--- General Error fetching members ---');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('------------------------------------');
      return [];
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _filteredMembers =
          _allMembers.where((member) {
            final nameLower = member.fullName.toLowerCase();
            final nimNipLower = member.nimNip.toLowerCase();
            final searchLower = query.toLowerCase();
            return nameLower.contains(searchLower) ||
                nimNipLower.contains(searchLower);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Anggota',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D7092),
        centerTitle: true,
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterMembers,
                decoration: InputDecoration(
                  hintText: 'Search : (nama/nim/nrp)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          Expanded(
            // Gunakan RefreshIndicator untuk pull-to-refresh
            child: RefreshIndicator(
              onRefresh:
                  _refreshMembers, // Panggil fungsi refresh saat ditarik ke bawah
              child: FutureBuilder<List<Member>>(
                future: _membersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading data: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _membersFuture = fetchMembers();
                              });
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No members found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  } else {
                    // ListView.builder sudah secara default bisa discroll jika isinya lebih dari layar
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = _filteredMembers[index];
                        return MemberCard(member: member);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget MemberCard untuk menampilkan detail setiap anggota
class MemberCard extends StatelessWidget {
  final Member member;

  const MemberCard({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EBF5),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMemberDetail('Nama', member.fullName),
                const SizedBox(height: 4),
                _buildMemberDetail('Nim/Nrp', member.nimNip),
                const SizedBox(height: 4),
                _buildMemberDetail('Status', member.status),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // MODIFIKASI BAGIAN INI UNTUK MENAMPILKAN GAMBAR
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300], // Placeholder background
              shape: BoxShape.circle,
              // Tambahkan gambar jika URL tersedia dan tidak kosong
              image:
                  member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(
                          member.avatarUrl!,
                        ), // Menggunakan avatarUrl
                        fit: BoxFit.cover, // Agar gambar pas di lingkaran
                      )
                      : null, // Jika tidak ada URL, tidak ada gambar latar belakang
            ),
            // Tampilkan ikon default jika tidak ada gambar
            child:
                member.avatarUrl == null || member.avatarUrl!.isEmpty
                    ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                    : null, // Jika ada gambar, jangan tampilkan ikon
          ),
        ],
      ),
    );
  }

  // Helper widget untuk detail anggota
  Widget _buildMemberDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70, // Align labels
          child: Text(
            '$label ',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Text(
          ': $value',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
