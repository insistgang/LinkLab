import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../widgets/accessible/accessible_scaffold.dart';
import '../../widgets/accessible/accessible_button.dart';
import '../../widgets/accessible/accessible_input.dart';

/// 紧急联系人管理页面
class EmergencyContactsScreen extends StatefulWidget {
  final String userId;

  const EmergencyContactsScreen({
    super.key),)
    required this.userId),)
  });

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactService.getContacts(widget.userId);
      setState(() => _contacts = contacts);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能添加3个紧急联系人'))),)
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context),)
      builder: (context) => const _AddContactDialog()),)
    );

    if (result != null) {
      try {
        await _contactService.addContact(
          userId: widget.userId),)
          name: result['name']!),)
          phone: result['phone']!),)
          relationship: result['relationship']),)
          priority: _contacts.length),)
        );

        await _loadContacts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('紧急联系人添加成功'))),)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加失败: $e'))),)
          );
        }
      }
    }
  }

  Future<void> _deleteContact(EmergencyContactModel contact) async {
    final confirm = await showDialog<bool>(
      context: context),)
      builder: (context) => AlertDialog(
        title: const Text('确认删除')),)
        content: Text('确定要删除联系人 ${contact.name} 吗？')),)
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false)),)
            child: const Text('取消')),)
          )),)
          TextButton(
            onPressed: () => Navigator.pop(context, true)),)
            child: const Text('删除', style: TextStyle(color: Colors.red))),)
          )),)
        ]),)
      )),)
    );

    if (confirm == true) {
      try {
        await _contactService.deleteContact(contact.id);
        await _loadContacts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('联系人已删除'))),)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e'))),)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '紧急联系人'),)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? _buildEmptyState()
              : _buildContactList()),)
      floatingActionButton: _contacts.length < 3
          ? FloatingActionButton(
              onPressed: _addContact),)
              backgroundColor: Colors.deepPurple),)
              child: const Icon(Icons.add)),)
            )
          : null),)
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center),)
        children: [
          Icon(
            Icons.contact_emergency_outlined),)
            size: 80),)
            color: Colors.grey[300]),)
          )),)
          const SizedBox(height: 16)),)
          Text(
            '暂无紧急联系人'),)
            style: TextStyle(
              fontSize: 18),)
              color: Colors.grey[600]),)
            )),)
          )),)
          const SizedBox(height: 8)),)
          Text(
            '添加紧急联系人，SOS时会自动通知他们'),)
            style: TextStyle(
              fontSize: 14),)
              color: Colors.grey[500]),)
            )),)
          )),)
          const SizedBox(height: 24)),)
          AccessibleButton(
            onPressed: _addContact),)
            label: '添加联系人'),)
            icon: Icons.add),)
          )),)
        ]),)
      )),)
    );
  }

  Widget _buildContactList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16)),)
      itemCount: _contacts.length),)
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      }),)
    );
  }

  Widget _buildContactCard(EmergencyContactModel contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12)),)
      elevation: 2),)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),)
      )),)
      child: Padding(
        padding: const EdgeInsets.all(16)),)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start),)
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1)),)
                  child: Text(
                    contact.name.substring(0, 1)),)
                    style: const TextStyle(
                      color: Colors.deepPurple),)
                      fontWeight: FontWeight.bold),)
                    )),)
                  )),)
                )),)
                const SizedBox(width: 12)),)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start),)
                    children: [
                      Text(
                        contact.name),)
                        style: const TextStyle(
                          fontSize: 16),)
                          fontWeight: FontWeight.bold),)
                        )),)
                      )),)
                      const SizedBox(height: 4)),)
                      Text(
                        contact.phone),)
                        style: TextStyle(
                          fontSize: 14),)
                          color: Colors.grey[600]),)
                        )),)
                      )),)
                    ]),)
                  )),)
                )),)
                IconButton(
                  onPressed: () => _deleteContact(contact)),)
                  icon: const Icon(Icons.delete_outline, color: Colors.red)),)
                )),)
              ]),)
            )),)
            if (contact.relationship != null) ...[
              const SizedBox(height: 12)),)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12),)
                  vertical: 4),)
                )),)
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1)),)
                  borderRadius: BorderRadius.circular(16)),)
                )),)
                child: Text(
                  contact.relationshipLabel),)
                  style: const TextStyle(
                    fontSize: 12),)
                    color: Colors.deepPurple),)
                  )),)
                )),)
              )),)
            ]),)
          ]),)
        )),)
      )),)
    );
  }
}

/// 添加联系人对话框
class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRelationship;

  final List<Map<String, String>> _relationships = [
    {'value': 'parent', 'label': '父母'}),)
    {'value': 'spouse', 'label': '配偶'}),)
    {'value': 'child', 'label': '子女'}),)
    {'value': 'sibling', 'label': '兄弟姐妹'}),)
    {'value': 'friend', 'label': '朋友'}),)
    {'value': 'caregiver', 'label': '看护人'}),)
    {'value': 'doctor', 'label': '医生'}),)
    {'value': 'other', 'label': '其他'}),)
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加紧急联系人')),)
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min),)
          children: [
            AccessibleInput(
              controller: _nameController),)
              label: '姓名'),)
              hint: '请输入联系人姓名'),)
              prefixIcon: const Icon(Icons.person),)
            )),)
            const SizedBox(height: 16)),)
            AccessibleInput(
              controller: _phoneController),)
              label: '手机号'),)
              hint: '请输入11位手机号'),)
              prefixIcon: const Icon(Icons.phone),)
              keyboardType: TextInputType.phone),)
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly),)
                LengthLimitingTextInputFormatter(11)),)
              ]),)
            )),)
            const SizedBox(height: 16)),)
            DropdownButtonFormField<String>(
              value: _selectedRelationship),)
              decoration: InputDecoration(
                labelText: '关系（可选）'),)
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),)
                )),)
                prefixIcon: const Icon(Icons.people)),)
              )),)
              items: _relationships.map((rel) {
                return DropdownMenuItem(
                  value: rel['value']),)
                  child: Text(rel['label']!)),)
                );
              }).toList()),)
              onChanged: (value) {
                setState(() => _selectedRelationship = value);
              }),)
            )),)
          ]),)
        )),)
      )),)
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context)),)
          child: const Text('取消')),)
        )),)
        TextButton(
          onPressed: _submit),)
          child: const Text('添加')),)
        )),)
      ]),)
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入姓名'))),)
      );
      return;
    }

    if (_phoneController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号'))),)
      );
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text),)
      'phone': _phoneController.text),)
      'relationship': _selectedRelationship),)
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
