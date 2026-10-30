import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Keys Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4059ad)),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flutter Keys Lab')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'See widget identity in action',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore the shopping cart from the article in two separate flows. Try the same actions in each and compare what happens to local widget state.',
            ),
            const SizedBox(height: 24),
            _flowCard(context, false),
            const SizedBox(height: 12),
            _flowCard(context, true),
            const SizedBox(height: 24),
            const Text(
              'Each flow starts fresh. Quantities and preview choices are deliberately kept in widget State to make identity visible; a real cart should keep business data in an appropriate state holder.',
            ),
          ],
        ),
      ),
    ),
  );
  Widget _flowCard(BuildContext context, bool keyed) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(keyed ? Icons.key : Icons.key_off)),
      title: Text(keyed ? 'With keys' : 'Without keys'),
      subtitle: Text(
        keyed
            ? 'Track items and drafts, reset and move previews.'
            : 'See what positional identity does to local state.',
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => LabPage(keyed: keyed)),
      ),
    ),
  );
}

class CartItem {
  const CartItem(this.id, this.name, this.price);
  final String id, name;
  final int price;
}

class Draft {
  Draft(this.color);
  final String color;
}

class LabPage extends StatefulWidget {
  const LabPage({super.key, required this.keyed});
  final bool keyed;
  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  List<CartItem> products = const [
    CartItem('bag-101', 'Everyday Tote', 1299),
    CartItem('wallet-102', 'Classic Wallet', 499),
    CartItem('watch-103', 'Minimal Watch', 1899),
  ];
  List<Draft> drafts = [Draft('Red'), Draft('Black')];
  Key previewKey = UniqueKey();
  final GlobalKey movingKey = GlobalKey();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool floating = false;
  int rebuilds = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.keyed ? 'With keys' : 'Without keys')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _intro(
              '01',
              'Sort the cart',
              widget.keyed
                  ? 'ValueKey(product.id) keeps quantity with the product, even when fresh model objects arrive.'
                  : 'Add to the tote, then sort by price. Quantity follows the position because the tiles have no keys.',
            ),
            ...products.map(
              (p) => CartTile(
                key: widget.keyed ? ValueKey(p.id) : null,
                product: p,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () =>
                        products = [...products]
                          ..sort((a, b) => a.price.compareTo(b.price)),
                  ),
                  icon: const Icon(Icons.sort),
                  label: const Text('Sort by price'),
                ),
                OutlinedButton(
                  onPressed: () => setState(
                    () => products = [
                      for (final p in products) CartItem(p.id, p.name, p.price),
                    ],
                  ),
                  child: const Text('Refresh models'),
                ),
              ],
            ),
            const Divider(height: 48),
            _intro(
              '02',
              'Reorder customization drafts',
              widget.keyed
                  ? 'ObjectKey tracks each draft instance. Replacing an instance starts a new editor.'
                  : 'Add an edit to Red, then swap. The editor state stays at its position.',
            ),
            ...drafts.map(
              (d) =>
                  DraftTile(key: widget.keyed ? ObjectKey(d) : null, draft: d),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      setState(() => drafts = drafts.reversed.toList()),
                  child: const Text('Swap drafts'),
                ),
                OutlinedButton(
                  onPressed: () => setState(
                    () => drafts = [Draft(drafts[0].color), ...drafts.skip(1)],
                  ),
                  child: const Text('Replace first draft'),
                ),
              ],
            ),
            const Divider(height: 48),
            _intro(
              '03',
              'Start a new preview',
              widget.keyed
                  ? 'A stored UniqueKey changes only when you start a new preview. A parent rebuild keeps the selection.'
                  : 'Without a new identity, starting a new preview rebuilds the parent but leaves the selection intact.',
            ),
            Column(
              children: [ProductPreview(key: widget.keyed ? previewKey : null)],
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => setState(() {
                    if (widget.keyed) {
                      previewKey = UniqueKey();
                    }
                  }),
                  child: const Text('Start new preview'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => rebuilds++),
                  child: const Text('Rebuild parent'),
                ),
              ],
            ),
            Text(
              'Parent rebuilds: $rebuilds',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 48),
            _intro(
              '04',
              'Move the preview',
              widget.keyed
                  ? 'The GlobalKey moves the same preview between two parents in one frame, preserving its state.'
                  : 'Moving between different parents creates a new preview, so its selection resets.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Floating preview'),
              value: floating,
              onChanged: (v) => setState(() => floating = v),
            ),
            _previewSlot('Main content', !floating),
            const SizedBox(height: 8),
            _previewSlot('Floating panel', floating),
            const Divider(height: 48),
            _intro(
              '05',
              'Checkout',
              widget.keyed
                  ? 'A GlobalKey<FormState> lets the button validate the form from outside it.'
                  : 'A Builder inside the Form can also access FormState without a GlobalKey.',
            ),
            Form(
              key: widget.keyed ? formKey : null,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Phone is required'
                        : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (formContext) => FilledButton(
                      onPressed: () {
                        final valid = widget.keyed
                            ? formKey.currentState!.validate()
                            : Form.of(formContext).validate();
                        if (valid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Checkout validated — no order was placed.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Place order'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    ),
  );
  Widget _intro(String number, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPERIMENT $number',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(description),
      ],
    ),
  );
  Widget _previewSlot(String title, bool active) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (active)
          ProductPreview(key: widget.keyed ? movingKey : null)
        else
          const Text('Preview is in the other panel.'),
      ],
    ),
  );
}

class CartTile extends StatefulWidget {
  const CartTile({super.key, required this.product});
  final CartItem product;
  @override
  State<CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<CartTile> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(widget.product.name),
      subtitle: Text('\$${widget.product.price} · Quantity: $quantity'),
      trailing: IconButton(
        tooltip: 'Add ${widget.product.name}',
        onPressed: () => setState(() => quantity++),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ),
  );
}

class DraftTile extends StatefulWidget {
  const DraftTile({super.key, required this.draft});
  final Draft draft;
  @override
  State<DraftTile> createState() => _DraftTileState();
}

class _DraftTileState extends State<DraftTile> {
  int edits = 0;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text('${widget.draft.color} draft'),
      subtitle: Text('Local edits: $edits'),
      trailing: TextButton(
        onPressed: () => setState(() => edits++),
        child: const Text('Add edit'),
      ),
    ),
  );
}

class ProductPreview extends StatefulWidget {
  const ProductPreview({super.key});
  @override
  State<ProductPreview> createState() => _ProductPreviewState();
}

class _ProductPreviewState extends State<ProductPreview> {
  bool selected = false;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Gift wrap selected'),
      subtitle: const Text('Temporary preview option'),
      value: selected,
      onChanged: (v) => setState(() => selected = v ?? false),
    ),
  );
}
