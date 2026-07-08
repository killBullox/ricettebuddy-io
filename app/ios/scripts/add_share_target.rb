require 'xcodeproj'

proj_path = ARGV[0]
project = Xcodeproj::Project.open(proj_path)

TEAM = '3984V5N8RL'
EXT = 'ShareExtension'
EXT_BUNDLE = 'io.beetit.recipes.ShareExtension'

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'no Runner target' unless runner

# --- idempotenza: rimuovi target/embed/prodotto esistenti ---
runner.build_phases.grep(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase).each do |ph|
  ph.files.dup.each do |bf|
    dn = (bf.display_name || '').to_s
    bf.remove_from_project if dn.include?(EXT)
  end
end
project.targets.select { |t| t.name == EXT }.each(&:remove_from_project)

# --- crea il target app extension ---
ext = project.new_target(:app_extension, EXT, :ios, '13.0')

# gruppo + sorgente
grp = project.main_group['Share'] || project.main_group.new_group('Share', 'Share')
swift = grp.files.find { |f| f.path.to_s.end_with?('ShareViewController.swift') }
swift ||= grp.new_reference('ShareViewController.swift')
ext.source_build_phase.add_file_reference(swift)

# build settings
ext.build_configurations.each do |c|
  bs = c.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = EXT_BUNDLE
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['INFOPLIST_FILE'] = 'Share/Info.plist'
  bs['CODE_SIGN_ENTITLEMENTS'] = 'Share/Share.entitlements'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['DEVELOPMENT_TEAM'] = TEAM
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  bs['SWIFT_VERSION'] = '5.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SKIP_INSTALL'] = 'YES'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['LD_RUNPATH_SEARCH_PATHS'] =
    ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

# embed dell'extension dentro Runner
embed = runner.build_phases.grep(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
              .find { |p| p.symbol_dst_subfolder_spec == :plug_ins }
embed ||= runner.new_copy_files_build_phase('Embed App Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(ext.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy', 'CodeSignOnCopy'] }

# IMPORTANTE: la fase "Embed App Extensions" deve stare PRIMA del Run Script
# "Thin Binary" di Flutter, altrimenti Xcode segnala un ciclo di dipendenze.
runner.build_phases.delete(embed)
thin_idx = runner.build_phases.index do |ph|
  ph.respond_to?(:name) && ph.name.to_s.include?('Thin Binary')
end
if thin_idx
  runner.build_phases.insert(thin_idx, embed)
else
  runner.build_phases << embed
end

# Runner dipende dall'extension + entitlements (App Group)
runner.add_dependency(ext)
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

project.save
puts 'XCODEPROJ_OK'
