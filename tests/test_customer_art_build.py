"""Authoring contract: adding a person or pose rebuilds only that character."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from PIL import Image

spec=importlib.util.spec_from_file_location('customer_builder',Path(__file__).resolve().parents[1]/'tools/prepare_customers.py')
builder=importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class CustomerBuildTests(unittest.TestCase):
    def test_independent_characters_and_extensible_named_poses(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            definitions=root/'art/characters';definitions.mkdir(parents=True)
            output=root/'assets/art';output.mkdir(parents=True)
            (output/'manifest.json').write_text('{}')
            seed=Image.new('RGBA',(32,16))
            seed.paste((180,50,30,255),(3,3,13,13))
            seed.paste((40,170,90,255),(19,3,29,13))
            seed.save(root/'poses.png')
            def character(name):
                return {'id':name,'atlas':'customer-'+name,'cell':[16,16],'sources':[{'kind':'atlas','path':'poses.png','cell':[16,16],'count':2,'animations':{'idle':[0],'walk':[1]}}],'fallbacks':{}}
            for name in ['alpha','beta']: (definitions/(name+'.json')).write_text(json.dumps(character(name)))
            with patch.multiple(builder,ROOT=root,DEFINITIONS=definitions,RUNTIME=output/'customer-characters.json'):
                builder.prepare()
                alpha=output/'customer-alpha.png';beta=output/'customer-beta.png'
                original_alpha=alpha.read_bytes();beta_stamp=beta.stat().st_mtime_ns;beta_bytes=beta.read_bytes()
                definition=character('alpha')
                definition['sources'].append({'kind':'atlas','path':'poses.png','cell':[16,16],'indices':[1],'animations':{'new_shared_pose':[0]}})
                (definitions/'alpha.json').write_text(json.dumps(definition))
                builder.prepare(['alpha'])
                self.assertNotEqual(alpha.read_bytes(),original_alpha)
                self.assertEqual(beta.stat().st_mtime_ns,beta_stamp)
                self.assertEqual(beta.read_bytes(),beta_bytes)
                catalog=json.loads((output/'customer-characters.json').read_text())
                self.assertEqual(catalog['alpha']['animations']['new_shared_pose'],[2])
                alpha_stamp=alpha.stat().st_mtime_ns
                (definitions/'gamma.json').write_text(json.dumps(character('gamma')))
                builder.prepare(['gamma'])
                self.assertTrue((output/'customer-gamma.png').exists())
                self.assertEqual(alpha.stat().st_mtime_ns,alpha_stamp)
                self.assertEqual(beta.stat().st_mtime_ns,beta_stamp)


if __name__=='__main__': unittest.main()
