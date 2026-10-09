const LabReport = require('../models/LabReport');

// GET /api/lab-reports
exports.getAll = async (req, res) => {
  try {
    const { category } = req.query;
    const filter = { patientId: req.user.id };
    if (category) filter.category = category;
    const reports = await LabReport.find(filter).sort({ testDate: -1 });
    res.json(reports);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};

// POST /api/lab-reports
exports.create = async (req, res) => {
  try {
    const { reportName, category, testDate, notes, documentUrl } = req.body;
    if (!reportName || !testDate) {
      return res.status(400).json({ message: 'Report name and test date are required.' });
    }
    const report = await LabReport.create({
      patientId: req.user.id,
      reportName,
      category,
      testDate,
      notes,
      documentUrl,
    });
    res.status(201).json(report);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};

// PUT /api/lab-reports/:id
exports.update = async (req, res) => {
  try {
    const { reportName, category, testDate, notes, documentUrl } = req.body;
    const report = await LabReport.findOneAndUpdate(
      { _id: req.params.id, patientId: req.user.id },
      { reportName, category, testDate, notes, documentUrl },
      { new: true }
    );
    if (!report) return res.status(404).json({ message: 'Report not found.' });
    res.json(report);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};

// DELETE /api/lab-reports/:id
exports.remove = async (req, res) => {
  try {
    const report = await LabReport.findOneAndDelete({
      _id: req.params.id,
      patientId: req.user.id,
    });
    if (!report) return res.status(404).json({ message: 'Report not found.' });
    res.json({ message: 'Report deleted.' });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};
