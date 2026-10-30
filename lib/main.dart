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

/// A server-backed cart item whose ID survives a model refresh.
///
/// In a cart that permits multiple lines for the same product, use a stable
/// cart-line ID instead so sibling keys remain unique.
class CartItem {
  const CartItem(this.id, this.name, this.price);
  final String id, name;
  final int price;
}

/// An unsaved customization session. Its object instance is its identity.
/// Recreating it, even with the same color, represents a new session.
class Draft {
  Draft(this.color);
  final String color;
}

/// Runs the same experiments in either keyed or unkeyed mode.
///
/// Each visit creates fresh page state. The unkeyed behavior is intentional:
/// it makes positional matching visible, rather than modeling a real cart.
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
  // Keep these keys in State rather than constructing them during build.
  // Only replacing previewKey should create a new preview identity.
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
            // Without a key, same-type tiles are matched by position, so their
            // local quantities can appear under different products after sorting.
            // With ValueKey, the stable ID associates each tile with its item.
            // A key helps reconciliation; it does not persist disposed state.
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
                // Simulate an API refresh: new instances, unchanged IDs.
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
            // ObjectKey compares object identity, not the fields of a draft.
            // Swapping the same instances preserves their editors; replacing an
            // instance gives the keyed editor a new State, even for equal data.
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
            // The wrapper provides a stable parent for the preview. A new
            // UniqueKey replaces its element and resets its local selection;
            // ordinary parent rebuilds reuse the stored key and preserve it.
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
            // Only one slot contains the preview at a time. A GlobalKey lets
            // Flutter reparent its element between these different parents when
            // it leaves one and enters the other in the same frame.
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
                  // Builder supplies a context below Form. Form.of can therefore
                  // validate without a GlobalKey. The keyed branch illustrates
                  // currentState access, which also works from outside the Form.
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

/// A cart row with deliberately local quantity, so element reuse is observable.
/// Production cart quantities generally belong in shared application state.
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

/// An editor whose local edit count makes draft identity visible during swaps.
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

/// A small stateful subtree used to demonstrate reset and reparenting.
/// Its temporary selection is separate from the cart's business data.
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
