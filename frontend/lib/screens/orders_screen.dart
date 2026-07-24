import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';
import 'dart:async';
import 'dart:js' as js;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _requestNotificationPermission();
    _fetchOrders().then((_) {
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollOrders();
    });
  }

  Future<void> _pollOrders() async {
    try {
      final list = await ApiService.getOrders();
      bool hasNewOrder = false;
      Order? latestNewOrder;
      if (_allOrders.isNotEmpty) {
        final existingIds = _allOrders.map((o) => o.id).toSet();
        for (var o in list) {
          if (!existingIds.contains(o.id)) {
            hasNewOrder = true;
            latestNewOrder = o;
            break;
          }
        }
      }

      setState(() {
        _allOrders = list;
      });
      _applyFilter();

      if (hasNewOrder) {
        _playOrderSound();
        if (latestNewOrder != null) {
          _showWebNotification(
            '🔔 New Order #${latestNewOrder.id} Received!',
            'Customer: ${latestNewOrder.customerName} - Total: ₹${latestNewOrder.totalPrice.toStringAsFixed(0)}',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 New Order Received! / புதிய ஆர்டர் வந்துள்ளது!'),
            backgroundColor: Color(0xFF00C853),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  void _requestNotificationPermission() {
    try {
      js.context.callMethod('eval', ["""
        if (window.Notification && Notification.permission !== "granted") {
          Notification.requestPermission();
        }
      """]);
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  void _showWebNotification(String title, String body) {
    try {
      js.context.callMethod('eval', ["""
        if (window.Notification && Notification.permission === "granted") {
          new Notification("$title", {
            body: "$body"
          });
        }
      """]);
    } catch (e) {
      debugPrint('Error showing web notification: $e');
    }
  }

  void _playOrderSound() {
    try {
      js.context.callMethod('eval', ["""
        (function() {
          var context = new (window.AudioContext || window.webkitAudioContext)();
          var osc1 = context.createOscillator();
          var gain1 = context.createGain();
          osc1.type = 'sine';
          osc1.frequency.setValueAtTime(783.99, context.currentTime); // G5
          gain1.gain.setValueAtTime(0.1, context.currentTime);
          gain1.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.15);
          osc1.connect(gain1);
          gain1.connect(context.destination);
          osc1.start();
          osc1.stop(context.currentTime + 0.15);

          setTimeout(function() {
            var osc2 = context.createOscillator();
            var gain2 = context.createGain();
            osc2.type = 'sine';
            osc2.frequency.setValueAtTime(1046.50, context.currentTime); // C6
            gain2.gain.setValueAtTime(0.1, context.currentTime);
            gain2.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.3);
            osc2.connect(gain2);
            gain2.connect(context.destination);
            osc2.start();
            osc2.stop(context.currentTime + 0.3);
          }, 120);
        })()
      """]);
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void _printReceipt(Order order) {
    final String itemsHtml = order.items.map((item) {
      return '''
        <tr>
          <td style="padding: 6px 0;">${item.name} x ${item.quantity}</td>
          <td style="padding: 6px 0; text-align: right;">₹${(item.price * item.quantity).toStringAsFixed(0)}</td>
        </tr>
      ''';
    }).join('');

    final String receiptHtml = '''
      <html>
        <head>
          <title>Receipt - Order #${order.id}</title>
          <style>
            body { font-family: 'Courier New', Courier, monospace; width: 300px; margin: 0 auto; padding: 20px; color: #000; font-size: 14px; line-height: 1.4; }
            .header { text-align: center; margin-bottom: 15px; border-bottom: 1px dashed #000; padding-bottom: 10px; }
            .title { font-size: 18px; font-weight: bold; margin: 0; }
            .subtitle { font-size: 11px; margin: 5px 0 0 0; }
            .details { margin-bottom: 15px; font-size: 12px; }
            .details div { margin-bottom: 4px; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 13px; }
            th { border-bottom: 1px dashed #000; padding: 6px 0; text-align: left; }
            .total { border-top: 1px dashed #000; border-bottom: 1px dashed #000; padding: 10px 0; font-weight: bold; display: flex; justify-content: space-between; font-size: 16px; margin-bottom: 15px; }
            .footer { text-align: center; font-size: 11px; border-top: 1px dashed #000; padding-top: 10px; margin-top: 20px; }
            @media print {
              body { width: 100%; padding: 0; }
              @page { margin: 0.5cm; }
            }
          </style>
        </head>
        <body>
          <div class="header">
            <h1 class="title">CURRY MAMA</h1>
            <p class="subtitle">Fresh Meat Store / கறிக்கடை</p>
          </div>
          <div class="details">
            <div><strong>Order ID:</strong> #${order.id}</div>
            <div><strong>Date:</strong> ${order.date}</div>
            <div><strong>Customer:</strong> ${order.customerName}</div>
            <div><strong>Phone:</strong> ${order.mobileNumber}</div>
            <div><strong>Address:</strong> ${order.address}</div>
            <div><strong>Payment:</strong> ${order.paymentMethod}</div>
          </div>
          <table>
            <thead>
              <tr>
                <th style="text-align: left;">Item</th>
                <th style="text-align: right;">Amount</th>
              </tr>
            </thead>
            <tbody>
              $itemsHtml
            </tbody>
          </table>
          <div class="total">
            <span>TOTAL:</span>
            <span>₹${order.totalPrice.toStringAsFixed(0)}</span>
          </div>
          <div class="footer">
            <p>Thank you for buying from Curry Mama!</p>
            <p>மீண்டும் வருக / Visit Again!</p>
          </div>
          <script>
            window.onload = function() {
              window.print();
              setTimeout(function() { window.close(); }, 500);
            }
          </script>
        </body>
      </html>
    ''';

    try {
      js.context.callMethod('eval', ["""
        window.curryMamaPrintReceipt = function(htmlContent) {
          var printWindow = window.open('', '_blank', 'width=600,height=600');
          printWindow.document.open();
          printWindow.document.write(htmlContent);
          printWindow.document.close();
        };
      """]);
      js.context.callMethod('curryMamaPrintReceipt', [receiptHtml]);
    } catch (e) {
      debugPrint('Printing error: $e');
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getOrders();
      setState(() {
        _allOrders = list;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _filteredOrders = _allOrders;
          break;
        case 1:
          _filteredOrders = _allOrders.where((o) => o.status == 'Pending').toList();
          break;
        case 2:
          _filteredOrders = _allOrders.where((o) => o.status == 'Completed').toList();
          break;
        case 3:
          _filteredOrders = _allOrders.where((o) => o.status == 'Cancelled').toList();
          break;
      }
    });
  }

  Future<void> _changeStatus(int orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId updated to $newStatus'), backgroundColor: Colors.green),
      );
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _changePaymentStatus(int orderId, String newPaymentStatus) async {
    try {
      await ApiService.updatePaymentStatus(orderId, newPaymentStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId payment marked as $newPaymentStatus'), backgroundColor: Colors.green),
      );
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CURRY MAMA FULFILLMENT',
                    style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Orders Log',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E2E),
                  foregroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Refresh Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters TabBar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF00C853),
            unselectedLabelColor: Colors.white38,
            indicatorColor: const Color(0xFF00C853),
            tabs: const [
              Tab(text: 'All Orders'),
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
          const SizedBox(height: 24),

          // Orders Table/List
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00C853))),
            )
          else if (_filteredOrders.isEmpty)
            const Expanded(
              child: Center(child: Text('No orders registered in this category.', style: TextStyle(color: Colors.white38))),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = _filteredOrders[index];
                  final isVerificationPending = order.paymentStatus == 'Verification Pending';
                  final isPaid = order.paymentStatus == 'Paid';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVerificationPending ? Colors.amber.withOpacity(0.6) : const Color(0xFF2E2E3E), 
                          width: isVerificationPending ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Order #${order.id}',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      if (isVerificationPending) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber, width: 1),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'VERIFICATION PENDING (UPI)',
                                                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.date,
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                              _buildStatusSelector(order),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(color: Color(0xFF2E2E3E), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CUSTOMER & DELIVERY DETAILS', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF00C853)),
                                        const SizedBox(width: 6),
                                        Text(
                                          order.mobileNumber.isEmpty ? 'N/A' : order.mobileNumber,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00C853)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            order.address.isEmpty ? 'N/A' : order.address,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ITEMS ORDERED', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: order.items.map((item) {
                                        return Text(
                                          '${item.name} x${item.quantity} (₹${item.price.toStringAsFixed(0)})',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('PAYMENT METHOD', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: order.paymentMethod.contains('Online') 
                                          ? Colors.blue.withOpacity(0.12)
                                          : const Color(0xFF00C853).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: order.paymentMethod.contains('Online')
                                            ? Colors.blue.withOpacity(0.4)
                                            : const Color(0xFF00C853).withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      order.paymentMethod.isEmpty ? 'N/A' : order.paymentMethod,
                                      style: TextStyle(
                                        color: order.paymentMethod.contains('Online') ? Colors.blue : const Color(0xFF00C853),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // PAYMENT STATUS BADGE & UTR VERIFICATION
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid 
                                          ? Colors.green.withOpacity(0.15) 
                                          : isVerificationPending 
                                              ? Colors.amber.withOpacity(0.15) 
                                              : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isPaid ? Colors.green : isVerificationPending ? Colors.amber : Colors.red,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isPaid 
                                          ? 'PAID (VERIFIED)' 
                                          : isVerificationPending 
                                              ? 'PENDING VERIFICATION' 
                                              : 'UNPAID',
                                      style: TextStyle(
                                        color: isPaid ? Colors.green : isVerificationPending ? Colors.amber : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  if (order.transactionId.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('UTR: ', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                        SelectableText(
                                          order.transactionId.startsWith('UPI-PENDING') 
                                              ? 'Not Provided (Verify by Amount)' 
                                              : order.transactionId,
                                          style: TextStyle(
                                            color: order.transactionId.startsWith('UPI-PENDING') ? Colors.white54 : Colors.amberAccent, 
                                            fontSize: 10, 
                                            fontWeight: FontWeight.bold, 
                                            fontFamily: 'monospace'
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // ADMIN PAYMENT VERIFICATION ACTION BUTTONS
                                  if (isVerificationPending || !isPaid) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _changePaymentStatus(order.id, 'Paid'),
                                          icon: const Icon(Icons.check_circle, size: 14, color: Colors.black),
                                          label: const Text('Verify & Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00C853),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        if (isVerificationPending) ...[
                                          const SizedBox(width: 6),
                                          OutlinedButton(
                                            onPressed: () => _changePaymentStatus(order.id, 'Unpaid'),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.redAccent),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text('Reject', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _printReceipt(order),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF00C853), width: 1.2),
                                      foregroundColor: const Color(0xFF00C853),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.print, size: 16),
                                    label: const Text('Print Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${order.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E2E3E)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: order.status,
          dropdownColor: const Color(0xFF16161E),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00C853)),
          items: const [
            DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(color: Colors.orange))),
            DropdownMenuItem(value: 'Completed', child: Text('Completed', style: TextStyle(color: Colors.green))),
            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled', style: TextStyle(color: Colors.red))),
          ],
          onChanged: (val) {
            if (val != null && val != order.status) {
              _changeStatus(order.id, val);
            }
          },
        ),
      ),
    );
  }
}
